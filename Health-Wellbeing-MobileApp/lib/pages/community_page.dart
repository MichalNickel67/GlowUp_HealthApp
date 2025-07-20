import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_wellbeing_app/pages/community/community_chat.dart';
import 'package:health_wellbeing_app/pages/community/upcoming_events.dart';

// A page that displays community features including challenges and leaderboard
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late Timer _timer;
  String dailyResetTime = "";
  String weeklyResetTime = "";
  String monthlyResetTime = "";

  // List to store leaderboard data
  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startResetTimer();
    _fetchLeaderboardData();
  }

  // Fetch leaderboard data from Firestore
  Future<void> _fetchLeaderboardData() async {
    setState(() {
      isLoading = true;
      leaderboardData = [];
    });

    try {
      // Fetch all users from UserDetails collection
      final userDocs = await FirebaseFirestore.instance.collection('UserDetails').get();

      for (var userDoc in userDocs.docs) {
        final userData = userDoc.data();

        // Only process if userData is not null
        final String name = userData['name'] as String? ?? 'Unknown User';

        // Safe conversion of MonthlyPoints to int
        final int monthlyPoints;
        final dynamic rawPoints = userData['MonthlyPoints'];
        if (rawPoints is int) {
          monthlyPoints = rawPoints;
        } else if (rawPoints is String) {
          monthlyPoints = int.tryParse(rawPoints) ?? 0;
        } else {
          monthlyPoints = 0;
        }

        leaderboardData.add({
          'name': name,
          'points': monthlyPoints,
          'uid': userDoc.id,
        });
        debugPrint('User: $name, Points: $monthlyPoints');
      }

      // Sort leaderboard by points in descending order
      leaderboardData.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

      // Keep only top 3 users
      if (leaderboardData.length > 3) {
        leaderboardData = leaderboardData.sublist(0, 3);
      }

      setState(() {
        isLoading = false;
      });

      debugPrint('Leaderboard data count: ${leaderboardData.length}');
    } catch (e) {
      debugPrint('Error fetching leaderboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Starts a timer to update the countdown timers for challenges
  void _startResetTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final DateTime now = DateTime.now();
      final DateTime midnight = DateTime(now.year, now.month, now.day, 23, 59);
      final DateTime nextSunday = now.add(Duration(days: 7 - now.weekday));
      final DateTime monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      setState(() {
        dailyResetTime = _formatTime(midnight.difference(now), forDaily: true);
        weeklyResetTime = _formatTime(nextSunday.difference(now));
        monthlyResetTime = _formatTime(monthEnd.difference(now));
      });
    });
  }

  // Formats the duration into a readable string
  String _formatTime(Duration duration, {bool forDaily = false}) {
    if (duration.inDays > 0) {
      return "${duration.inDays}d ${duration.inHours % 24}h";
    } else if (forDaily) {
      return "${duration.inHours}h ${duration.inMinutes % 60}m";
    } else {
      return "${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s";
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTopButtons(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildChallengeCards(),
                    const SizedBox(height: 10),
                    _buildLeaderboard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the top row of buttons for community features
  Widget _buildTopButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _topCardButton("Community Chat", Icons.chat, Colors.blue.shade600, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityChatPage()));
        }),
        const SizedBox(width: 10),
        _topCardButton("Upcoming Events", Icons.event, Colors.green.shade600, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const UpcomingEventsPage()));
        }),
      ],
    );
  }

  // Creates a button card for top navigation
  Widget _topCardButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 5),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the challenge cards section
  Widget _buildChallengeCards() {
    return Column(
      children: [
        _challengeCard("Daily Challenge", "Walk 5,000 steps", 10, dailyResetTime, 50),
        _challengeCard("Weekly Challenge", "Attend 2 community events", 50, weeklyResetTime, 70),
        _challengeCard("Monthly Challenge", "Run 20km total", 100, monthlyResetTime, 30),
      ],
    );
  }

  // Creates a challenge card with progress indicator
  Widget _challengeCard(String title, String description, int points, String timer, int progress) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress / 100, backgroundColor: Colors.grey.shade300, color: Colors.green),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("⏳ Resets in $timer", style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                Text("+$points pts", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Builds the leaderboard section
  Widget _buildLeaderboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("🏆 Monthly Leaderboard", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < leaderboardData.length; i++)
              _leaderboardItem(i + 1, leaderboardData[i]['name'] as String, leaderboardData[i]['points'] as int),
          ],
        ),
      ],
    );
  }

  // Creates a leaderboard item with rank, name and points
  Widget _leaderboardItem(int rank, String name, int points) {
    // Medal colors: Gold for 1st, Silver for 2nd, Bronze for 3rd
    Color medalColor;
    if (rank == 1) {
      medalColor = Colors.yellow.shade700; // Gold
    } else if (rank == 2) {
      medalColor = Colors.grey.shade600; // Silver
    } else {
      medalColor = Colors.brown.shade500; // Bronze
    }

    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 30, color: medalColor),
                  const SizedBox(width: 8),
                  Text(
                    "$rank",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: medalColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text("$points pts", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
        ),
      ),
    );
  }
}