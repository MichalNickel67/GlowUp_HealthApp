import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateGoalsPage extends StatefulWidget {
  const UpdateGoalsPage({super.key});

  @override
  State<UpdateGoalsPage> createState() => _UpdateGoalsPageState();
}

// Private implementation class for the state
class _UpdateGoalsPageState extends State<UpdateGoalsPage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Firestore instance for database operations
  final _firestore = FirebaseFirestore.instance;

  // Firebase Auth instance for user identification
  final _auth = FirebaseAuth.instance;

  // Variables to store user goals
  int? exerciseGoalPerWeek;
  int? meditationGoalPerWeek;
  int? productivityGoalPerWeek;
  int? sleepGoalInHours;
  bool isLoading = true;

  // Load user goals from Firestore
  Future<void> _loadUserGoals() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Get document from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('UserDetails').doc(user.uid).get();
      if (userDoc.exists) {
        // Update state with data from Firestore
        setState(() {
          // Use null-aware operator to handle missing fields
          exerciseGoalPerWeek = userDoc['exerciseGoalPerWeek'] ?? 0;
          meditationGoalPerWeek = userDoc['meditationGoalPerWeek'] ?? 0;
          productivityGoalPerWeek = userDoc['productivityGoalPerWeek'] ?? 0;
          sleepGoalInHours = userDoc['sleepGoalInHours'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserGoals();
  }

  // Save updated goals to Firestore
  void _saveUserGoals() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Update document in Firestore
      await _firestore.collection('UserDetails').doc(user.uid).update({
        'exerciseGoalPerWeek': exerciseGoalPerWeek,
        'meditationGoalPerWeek': meditationGoalPerWeek,
        'productivityGoalPerWeek': productivityGoalPerWeek,
        'sleepGoalInHours': sleepGoalInHours,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goals Updated')));
      // Navigate back to previous screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // AppBar - Top navigation bar
      appBar: AppBar(
        title: const Text('Update Goals'),
        backgroundColor: Colors.grey.withOpacity(0.7),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator()
      )
          : Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/goalsbg.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 250, left: 16, right: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Goal input
                  _buildInputField(
                    initialValue: exerciseGoalPerWeek?.toString(),
                    labelText: 'Exercise (days per week)',
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => exerciseGoalPerWeek = int.tryParse(value) ?? 0),
                  ),
                  const SizedBox(height: 16),

                  // Meditation Goal input
                  _buildInputField(
                    initialValue: meditationGoalPerWeek?.toString(),
                    labelText: 'Meditation (days per week)',
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => meditationGoalPerWeek = int.tryParse(value) ?? 0),
                  ),
                  const SizedBox(height: 16),

                  // Productivity Goal input
                  _buildInputField(
                    initialValue: productivityGoalPerWeek?.toString(),
                    labelText: 'Productivity (days per week)',
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => productivityGoalPerWeek = int.tryParse(value) ?? 0),
                  ),
                  const SizedBox(height: 16),

                  // Sleep Goal input
                  _buildInputField(
                    initialValue: sleepGoalInHours?.toString(),
                    labelText: 'Sleep (hours per night)',
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => sleepGoalInHours = int.tryParse(value) ?? 0),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for input fields
  Widget _buildInputField({
    required String? initialValue,
    required String labelText,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: onChanged,
    );
  }

  // Save button widget
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, // Make button full width
      child: ElevatedButton(
        onPressed: _saveUserGoals,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.blueAccent,
        ),
        child: const Text('Save', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}