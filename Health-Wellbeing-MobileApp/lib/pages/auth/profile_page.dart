import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'update_personal_info_page.dart';
import 'update_goals_page.dart';
import 'forgot_password_page.dart';
import 'login_page.dart';
import 'profile_delete_account.dart';

// ProfilePage widget allows users to view and manage their profile settings
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // Checks if the user is authenticated and redirects to login if needed
  Future<void> _checkAuthentication() async {
    // Wait for a moment to ensure Firebase Auth has initialized
    await Future.delayed(const Duration(milliseconds: 300));

    if (FirebaseAuth.instance.currentUser == null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    if (mounted) {
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  // Shows a confirmation dialog before logging out
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use specific context for dialog
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Close popup using dialog context
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close popup using dialog context
                await FirebaseAuth.instance.signOut(); // Logout
                if (!mounted) return; // Check if still mounted before using context

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()), // Redirect to login page
                );
              },
              child: const Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
      return const Scaffold(
        body: Center(child: Text("Redirecting to login...")),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile'),
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
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('UserDetails').doc(user.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // If there's an error or no data, create a new user document
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                // Create user document if it doesn't exist
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  try {
                    await FirebaseFirestore.instance.collection('UserDetails').doc(user.uid).set({
                      'name': user.displayName ?? 'User',
                      'email': user.email,
                      'createdAt': DateTime.now(),
                    });
                    if (mounted) {
                      // Refresh the page
                      setState(() {});
                    }
                  } catch (e) {
                    // Handle error silently
                    debugPrint("Error creating user document: $e");
                  }
                });

                // While creating, show a temporary profile with default values
                return _buildProfileContent(context, user, {'name': user.displayName ?? 'User'});
              }

              // Get user data safely with null-aware assignment
              // Using null-aware operator to replace if statement
              final userData = (snapshot.data?.data() as Map<String, dynamic>?) ?? {'name': user.displayName ?? 'User'};

              return _buildProfileContent(context, user, userData);
            },
          ),
        ],
      ),
    );
  }

  // Builds the profile content with user data
  Widget _buildProfileContent(BuildContext context, User user, Map<String, dynamic> userData) {
    // Use null-aware operator to safely extract name
    final String name = userData['name'] ?? 'User';

    return Padding(
      padding: const EdgeInsets.only(top: 100.0, left: 20.0, right: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Icon and Welcome Text
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.account_circle,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Welcome, $name",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  "Email: ${user.email}",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                _buildProfileButton(
                  context,
                  'Update Personal Info',
                  Icons.person_outline,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UpdatePersonalInfoPage()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildProfileButton(
                  context,
                  'Update Goals',
                  Icons.fitness_center,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UpdateGoalsPage()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildProfileButton(
                  context,
                  'Update Password',
                  Icons.lock_outline,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(),
          ),

          // Logout button
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () => _confirmLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),

          // Delete account button
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileDeleteAccount())
                  );
                },
                child: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create consistent profile buttons with icons and uniform width
  Widget _buildProfileButton(BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
        icon: Icon(icon, size: 30, color: Colors.black),
        label: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black)),
      ),
    );
  }
}