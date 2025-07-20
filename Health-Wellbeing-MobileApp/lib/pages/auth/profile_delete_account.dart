import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

// Widget that handles the account deletion process
class ProfileDeleteAccount extends StatefulWidget {
  const ProfileDeleteAccount({super.key});

  @override
  State<ProfileDeleteAccount> createState() => _ProfileDeleteAccountState();
}

class _ProfileDeleteAccountState extends State<ProfileDeleteAccount> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Shows a confirmation dialog before proceeding with account deletion
  void _confirmDeleteAccount(BuildContext context) {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password to continue';
      });
      return;
    }

    // Show confirmation dialog with warning
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete Account Permanently"),
          content: const Text(
            "WARNING: This action cannot be undone. Your account and all associated data will be permanently deleted from our systems.\n\nAre you absolutely sure you want to delete your account?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteUserAccount();
              },
              child: const Text("Delete My Account",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Shows a loading dialog during async operations
  void _showLoadingDialog() {
    final BuildContext dialogContext = context;

    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing..."),
            ],
          ),
        );
      },
    );
  }

  // Method to handle the re-authentication and account deletion process
  Future<void> _deleteUserAccount() async {
    if (_isDeleting) return; // Prevent multiple deletion attempts

    // Store context reference before async gap
    final BuildContext contextBeforeAsync = context;

    setState(() {
      _isDeleting = true;
      _errorMessage = '';
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading dialog
      _showLoadingDialog();

      // Re-authenticate the user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore collections
      final String uid = user.uid;

      // Delete UserDetails
      try {
        await FirebaseFirestore.instance.collection('UserDetails').doc(uid).delete();
      } catch (e) {
        // Replace print with proper logging
        debugPrint("Error deleting UserDetails: $e");
      }

      // Delete SleepTracker data
      try {
        final sleepTrackerDocs = await FirebaseFirestore.instance
            .collection('SleepTracker')
            .doc(uid)
            .collection('sleep_tracker')
            .get();

        for (final doc in sleepTrackerDocs.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting SleepTracker data: $e");
      }

      // Delete ExerciseTracker data
      try {
        final exerciseTrackerDocs = await FirebaseFirestore.instance
            .collection('ExerciseTracker')
            .doc(uid)
            .collection('exercise_tracker')
            .get();

        for (final doc in exerciseTrackerDocs.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting ExerciseTracker data: $e");
      }

      // Delete MeditationTracker data
      try {
        final meditationTrackerDocs = await FirebaseFirestore.instance
            .collection('MeditationTracker')
            .doc(uid)
            .collection('meditation_tracker')
            .get();

        for (final doc in meditationTrackerDocs.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting MeditationTracker data: $e");
      }

      // Delete NutritionTracker data
      try {
        final nutritionEntries = await FirebaseFirestore.instance
            .collection('NutritionTracker')
            .doc(uid)
            .collection('entries')
            .get();

        for (final doc in nutritionEntries.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting NutritionTracker data: $e");
      }

      // Delete ProductivityTracker data
      try {
        final productivityLogs = await FirebaseFirestore.instance
            .collection('ProductivityTracker')
            .doc(uid)
            .collection('productivity_logs')
            .get();

        for (final doc in productivityLogs.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting ProductivityTracker data: $e");
      }

      // Delete Redemptions data
      try {
        final redemptionsQuery = await FirebaseFirestore.instance
            .collection('Redemptions')
            .where('userId', isEqualTo: uid)
            .get();

        for (final doc in redemptionsQuery.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting Redemptions data: $e");
      }

      // Delete CommunityMessages data
      try {
        final communityMessagesDocs = await FirebaseFirestore.instance
            .collection('CommunityMessages')
            .doc(uid)
            .collection('messages')
            .get();

        for (final doc in communityMessagesDocs.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting CommunityMessages data: $e");
      }

      // Delete CommunityChats data
      try {
        final communityChatsQuery = await FirebaseFirestore.instance
            .collection('CommunityChats')
            .where('userId', isEqualTo: uid)
            .get();

        for (final doc in communityChatsQuery.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting CommunityChats data: $e");
      }

      // Delete events created by the user
      try {
        final eventsQuery = await FirebaseFirestore.instance
            .collection('events')
            .where('userId', isEqualTo: uid)
            .get();

        for (final doc in eventsQuery.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting events data: $e");
      }

      // Delete the user's authentication account
      await user.delete();

      // Handle navigation and UI updates after async operations
      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account successfully deleted"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (!mounted) return;

      // Close loading dialog if open
      Navigator.of(context).pop();

      String errorMsg = "Error deleting account";
      if (e.code == 'wrong-password') {
        errorMsg = "Incorrect password. Please try again.";
      } else if (e.code == 'too-many-requests') {
        errorMsg = "Too many attempts. Please try again later.";
      } else if (e.code == 'network-request-failed') {
        errorMsg = "Network error. Please check your connection.";
      } else {
        errorMsg = "Error: ${e.message}";
      }

      setState(() {
        _errorMessage = errorMsg;
        _isDeleting = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if open
      Navigator.of(context).pop();

      setState(() {
        _errorMessage = "Error: ${e.toString()}";
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: Colors.grey.withOpacity(0.7),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/profilebg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Delete Your Account",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            "This action will permanently delete your account and all data associated with it. This cannot be undone.",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 25),
                          const Text(
                            "Please enter your password to confirm:",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Password',
                              errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            enableSuggestions: false,
                            autocorrect: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: _isDeleting
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: () => _confirmDeleteAccount(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Delete My Account",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}