import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile_page.dart';

// Widget that allows users to enter and save their personal details
class UserDetailsPage extends StatefulWidget {
  final String uid;

  // Creates a UserDetailsPage with the required user ID
  const UserDetailsPage({super.key, required this.uid});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController exerciseGoalController = TextEditingController();
  final TextEditingController meditationGoalController = TextEditingController();
  final TextEditingController sleepGoalController = TextEditingController();
  final TextEditingController productivityGoalController = TextEditingController();

  String selectedGender = 'Male';

  // Saves the user details to Firestore and navigates to the profile page
  Future<void> saveUserDetails() async {
    try {
      await _firestore.collection("UserDetails").doc(widget.uid).set({
        "name": nameController.text.trim(),
        "age": int.tryParse(ageController.text.trim()) ?? 0,
        "gender": selectedGender,
        "height": int.tryParse(heightController.text.trim()) ?? 0,
        "weight": int.tryParse(weightController.text.trim()) ?? 0,
        "exerciseGoalPerWeek": _limitGoal(exerciseGoalController.text.trim()),
        "meditationGoalPerWeek": _limitGoal(meditationGoalController.text.trim()),
        "sleepGoalInHours": int.tryParse(sleepGoalController.text.trim()) ?? 0,
        "productivityGoalPerWeek": _limitGoal(productivityGoalController.text.trim()),
        "MonthlyPoints": 0, // Initialise monthly points
        "Points": 0, // Initialise total points
      }, SetOptions(merge: true)); // Merge fields to avoid overwriting previous data

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ User details saved successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error saving details: $e")),
      );
    }
  }

  // Limits goal values to a maximum of 7
  int _limitGoal(String value) {
    int goal = int.tryParse(value) ?? 0;
    return goal > 7 ? 7 : goal; // Limits goal to a max of 7
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Ensure the background covers the entire screen
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/userdetailsbg.png"),
            fit: BoxFit.cover,
          ),
        ),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        width: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Welcome Header
                  const Text(
                    "Let's Get to Know You!",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Complete your profile to personalise your experience",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  _buildTextField('First Name', nameController),
                  const SizedBox(height: 12),
                  _buildTextField('Age', ageController, isNumber: true),
                  const SizedBox(height: 12),
                  _buildDropdownField('Gender', selectedGender, ['Male', 'Female', 'Other'], (val) => setState(() => selectedGender = val)),
                  const SizedBox(height: 12),
                  _buildTextField('Height (cm)', heightController, isNumber: true),
                  const SizedBox(height: 12),
                  _buildTextField('Weight (kg)', weightController, isNumber: true),
                  const SizedBox(height: 12),

                  // Goal Fields with Limits
                  _buildTextField('Exercise Goal (per week, max 7)', exerciseGoalController, isNumber: true),
                  const SizedBox(height: 12),
                  _buildTextField('Meditation Goal (per week, max 7)', meditationGoalController, isNumber: true),
                  const SizedBox(height: 12),
                  _buildTextField('Sleep Goal (hours per day)', sleepGoalController, isNumber: true),
                  const SizedBox(height: 12),
                  _buildTextField('Productivity Goal (per week, max 7)', productivityGoalController, isNumber: true),
                  const SizedBox(height: 20),

                  // Save Button
                  ElevatedButton(
                    onPressed: saveUserDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: options.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (newValue) => onChanged(newValue!),
      ),
    );
  }
}