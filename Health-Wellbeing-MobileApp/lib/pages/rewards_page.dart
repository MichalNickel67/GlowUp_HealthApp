import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// A page that displays available rewards and allows users to redeem them using points
// This widget shows a list of gift card rewards that users can redeem with points earn in the app
class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  // Firebase instances for authentication and database access
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int userPoints = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch user points when the page loads
    _fetchUserPoints();
  }

  // Fetches the current user's point balance from Firestore
  Future<void> _fetchUserPoints() async {
    setState(() {
      isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get the user document from Firestore
        final DocumentSnapshot userDoc = await _firestore
            .collection('UserDetails')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          // Extract points from user data
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userPoints = userData['Points'] ?? 0;
            isLoading = false;
          });
        } else {
          // User document doesn't exist or is empty
          setState(() {
            isLoading = false;
          });
        }
      } else {
        // No user is logged in
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Error occurred during fetch
      setState(() {
        isLoading = false;
      });

      final BuildContext currentContext = context;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error fetching points: $e')),
      );
    }
  }

  // Processes a reward redemption request
  // Uses Firestore transaction to ensure updates to both the user's point balance and creating redemption record
  Future<void> _redeemReward(String rewardId, int pointCost, String rewardName) async {
    // Store context to avoid async gap warning
    final BuildContext currentContext = context;

    // Check if user has enough points
    if (userPoints < pointCost) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Not enough points to redeem this reward')),
      );
      return;
    }

    // Verify user is logged in
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        // Get user document reference
        final userDocRef = _firestore.collection('UserDetails').doc(currentUser.uid);
        // Create redemption document reference
        final redemptionDocRef = _firestore.collection('Redemptions').doc();

        // Deduct points from user account
        transaction.update(userDocRef, {
          'Points': FieldValue.increment(-pointCost),
        });

        // Create redemption record
        transaction.set(redemptionDocRef, {
          'userId': currentUser.uid,
          'rewardId': rewardId,
          'rewardName': rewardName,
          'pointCost': pointCost,
          'timestamp': FieldValue.serverTimestamp(),
          'email': currentUser.email,
          'status': 'pending', // Status field for tracking
        });
      });

      // Refresh points after successful redemption
      await _fetchUserPoints();
      // Show success dialog with email notification
      _showRedemptionSuccessDialog(rewardName, currentContext);
    } catch (e) {
      // Handle redemption errors
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error redeeming reward: $e')),
      );
    }
  }

  // Displays a success dialog after reward redemption
  // Informs the user that redemption was successful and provides information about when to expect the reward code
  void _showRedemptionSuccessDialog(String rewardName, BuildContext currentContext) {
    showDialog(
      context: currentContext,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 28),
              const SizedBox(width: 10),
              const Text(
                'Redemption Successful',
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have successfully redeemed $rewardName.'),
              const SizedBox(height: 16),
              const Text(
                'Please check your email for the redemption code.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: It may take up to 24 hours to receive your code.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rewards',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          // Display points in the top right corner
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '$userPoints pts',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gift cards section title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Gift Cards',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Build list of reward items
            _buildRewardsList(
              [
                RewardItem(
                  id: 'amazon-5',
                  name: 'Amazon £5 Gift Card',
                  description: 'Redeem for a £5 Amazon gift card',
                  pointCost: 500,
                  icon: Icons.card_giftcard,
                ),
                RewardItem(
                  id: 'amazon-10',
                  name: 'Amazon £10 Gift Card',
                  description: 'Redeem for a £10 Amazon gift card',
                  pointCost: 1000,
                  icon: Icons.card_giftcard,
                ),
                RewardItem(
                  id: 'starbucks-5',
                  name: 'Starbucks £5 Gift Card',
                  description: 'Redeem for a £5 Starbucks gift card',
                  pointCost: 500,
                  icon: Icons.coffee,
                ),
                RewardItem(
                  id: 'applemusic-10',
                  name: 'Apple Music £10 Gift Card',
                  description: 'Redeem for a £10 Apple Music gift card',
                  pointCost: 1000,
                  icon: Icons.music_note,
                ),
                RewardItem(
                  id: 'netflix-10',
                  name: 'Netflix £10 Gift Card',
                  description: 'Redeem for a £10 Netflix gift card',
                  pointCost: 1000,
                  icon: Icons.movie,
                ),
                RewardItem(
                  id: 'spotify-10',
                  name: 'Spotify £10 Gift Card',
                  description: 'Redeem for a £10 Spotify gift card',
                  pointCost: 1000,
                  icon: Icons.headset,
                ),
                RewardItem(
                  id: 'googleplay-5',
                  name: 'Google Play £5 Gift Card',
                  description: 'Redeem for a £5 Google Play gift card',
                  pointCost: 500,
                  icon: Icons.play_arrow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Builds a ListView of reward cards from the provided list of RewardItems
  Widget _buildRewardsList(List<RewardItem> rewards) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final bool canAfford = userPoints >= reward.pointCost;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              reward.icon,
              color: canAfford ? Colors.green : Colors.grey,
              size: 36,
            ),
            title: Text(
              reward.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            subtitle: Text(reward.description),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Point cost display
                Text(
                  '${reward.pointCost} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canAfford ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                // Availability status
                Text(
                  canAfford ? 'Available' : 'Not enough points',
                  style: TextStyle(
                    fontSize: 12,
                    color: canAfford ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            onTap: canAfford
                ? () => _showRedeemConfirmation(context, reward)
                : null,
            enabled: canAfford, // Disable tile if user does not have enough points
          ),
        );
      },
    );
  }

  // Shows a confirmation dialog box before redeeming a reward
  void _showRedeemConfirmation(BuildContext context, RewardItem reward) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Redemption'),
          content: Text(
              'Are you sure you want to redeem ${reward.name} for ${reward.pointCost} points?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redeemReward(reward.id, reward.pointCost, reward.name);
              },
              child: const Text('REDEEM'),
            ),
          ],
        );
      },
    );
  }
}

// A data class representing a reward item that can be redeemed
// Contains all necessary information about a reward
class RewardItem {
  final String id;
  final String name;
  final String description;
  final int pointCost;
  final IconData icon;

  RewardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.pointCost,
    required this.icon,
  });
}