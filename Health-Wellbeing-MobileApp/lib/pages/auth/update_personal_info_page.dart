import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// A page for updating user personal information
class UpdatePersonalInfoPage extends StatefulWidget {
  const UpdatePersonalInfoPage({super.key});

  @override
  State<UpdatePersonalInfoPage> createState() => UpdatePersonalInfoPageState();
}

// State for the UpdatePersonalInfoPage widget
class UpdatePersonalInfoPageState extends State<UpdatePersonalInfoPage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Firebase Firestore instance
  final _firestore = FirebaseFirestore.instance;

  // Firebase Auth instance
  final _auth = FirebaseAuth.instance;

  // User information fields
  String? name;
  int? age;
  String? gender;
  String? height;
  String? weight;
  bool isLoading = true; // Track loading state

  // Gender dropdown options
  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  // Loads user information from Firestore
  Future<void> _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Get document from Firestore
      DocumentSnapshot userDoc =
      await _firestore.collection('UserDetails').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          // Cast userDoc.data() to Map to access fields
          final data = userDoc.data() as Map<String, dynamic>?;
          name = data?['name'] as String? ?? '';

          // Ensure proper int conversion
          final rawAge = data?['age'];
          age = (rawAge is int) ? rawAge : (rawAge is num ? rawAge.toInt() : 0);

          gender = data?['gender'] as String? ?? 'Male'; // Default gender
          height = data?['height'] as String? ?? '';
          weight = data?['weight'] as String? ?? '';
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
    _loadUserInfo();
  }

  // Saves updated user information to Firestore
  void _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't save if validation fails
    }

    final user = _auth.currentUser;
    if (user != null) {
      // Update document in Firestore
      await _firestore.collection('UserDetails').doc(user.uid).update({
        'name': name,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Personal Info Updated')));
        Navigator.pop(context); // Return to previous screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Update Personal Info'),
        backgroundColor: Colors.grey.withOpacity(0.7),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/personalinfobg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Form content
          SingleChildScrollView(
            // Add scrolling capability
            child: Padding(
              padding: const EdgeInsets.only(top: 200, left: 16, right: 16, bottom: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name input
                    _buildInputField(
                      initialValue: name,
                      labelText: 'Name',
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter your name' : null,
                      onChanged: (value) => setState(() => name = value),
                    ),
                    const SizedBox(height: 16),

                    // Age input
                    _buildInputField(
                      initialValue: age?.toString(),
                      labelText: 'Age',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() => age = int.tryParse(value) ?? 0),
                    ),
                    const SizedBox(height: 16),

                    // Gender dropdown
                    _buildDropdownField(
                      value: gender,
                      labelText: 'Gender',
                      items: genderOptions.map((String gender) {
                        return DropdownMenuItem(value: gender, child: Text(gender));
                      }).toList(),
                      onChanged: (value) => setState(() => gender = value),
                    ),
                    const SizedBox(height: 16),

                    // Height input in cm
                    _buildInputField(
                      initialValue: height,
                      labelText: 'Height (cm)',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() => height = value),
                    ),
                    const SizedBox(height: 16),

                    // Weight input in kg
                    _buildInputField(
                      initialValue: weight,
                      labelText: 'Weight (kg)',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() => weight = value),
                    ),
                    const SizedBox(height: 32),

                    // Save button under input fields
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Creating consistent text input fields
  Widget _buildInputField({
    required String? initialValue,
    required String labelText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
      validator: validator,
      onChanged: onChanged,
    );
  }

  // Creating consistent dropdown fields
  Widget _buildDropdownField({
    required String? value,
    required String labelText,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // Save button
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveUserInfo,
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