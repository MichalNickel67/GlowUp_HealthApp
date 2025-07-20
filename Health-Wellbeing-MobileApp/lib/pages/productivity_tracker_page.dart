import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// A page that allows users to track their productivity metrics
// This widget displays a form for users to input various productivity metrics
class ProductivityTrackerPage extends StatefulWidget {
  const ProductivityTrackerPage({super.key});

  @override
  State<ProductivityTrackerPage> createState() => _ProductivityTrackerPageState();
}

class _ProductivityTrackerPageState extends State<ProductivityTrackerPage> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  DateTime _date = DateTime.now();
  int _focusedMinutes = 0;
  int _tasksCompleted = 0;
  double _productivityRating = 3.0; // 1-5 scale
  double _distractionLevel = 3.0; // 1-5 scale
  String _mainActivity = 'Studying'; // Default selection

  bool _isLoading = false;

  // List of activity options for the dropdown
  final List<String> _activityOptions = [
    'Studying',
    'Work',
    'Reading',
    'Creative Work',
    'Household Chores',
    'Socializing',
    'Self-Improvement',
    'Planning & Organizing',
    'Problem-Solving & Critical Thinking'
  ];

  // Shows a date picker and updates the selected date
  Future<void> _selectDate(BuildContext context) async {
    // Store context in local variable to avoid async gap warning
    final BuildContext currentContext = context;

    final DateTime? picked = await showDatePicker(
      context: currentContext,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  // Submits productivity data to Firestore
  Future<void> _submitData() async {
    final BuildContext currentContext = context;
    if (user == null) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit data')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare data for Firestore
        Map<String, dynamic> productivityData = {
          'date': Timestamp.fromDate(_date),
          'focusedMinutes': _focusedMinutes,
          'tasksCompleted': _tasksCompleted,
          'productivityRating': _productivityRating,
          'mainActivity': _mainActivity,
          'distractionLevel': _distractionLevel,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Generate a unique document ID using date and timestamp
        String docId = '${DateFormat('yyyy-MM-dd').format(_date)}-${DateTime.now().millisecondsSinceEpoch}';

        // Save to Firestore under ProductivityTracker/{userId}/productivity_logs/{docId}
        await FirebaseFirestore.instance
            .collection('ProductivityTracker')
            .doc(user!.uid)
            .collection('productivity_logs')
            .doc(docId)
            .set(productivityData);

        // Reset form fields after successful submission
        setState(() {
          _focusedMinutes = 0;
          _tasksCompleted = 0;
          _productivityRating = 3.0;
          _distractionLevel = 3.0;
          _mainActivity = 'Studying';
        });

        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Productivity data saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Tracker'),
        backgroundColor: Colors.amber.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            // Productivity tracker form
            Form(
              key: _formKey,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title section
                      const Text(
                        'Track Your Productivity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date selection
                      ListTile(
                        title: const Text('Date'),
                        subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(_date)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context),
                      ),

                      const SizedBox(height: 16),

                      // Main Activity dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Main Activity',
                          border: OutlineInputBorder(),
                        ),
                        value: _activityOptions.contains(_mainActivity) ? _mainActivity : _activityOptions.first,
                        items: _activityOptions.map((String activity) {
                          return DropdownMenuItem<String>(
                            value: activity,
                            child: Text(activity),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _mainActivity = newValue;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Focused Minutes input field
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Focused Minutes',
                          border: OutlineInputBorder(),
                          suffixText: 'min',
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _focusedMinutes.toString(),
                        onChanged: (value) {
                          _focusedMinutes = int.tryParse(value) ?? 0;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tasks Completed input field
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Tasks Completed',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _tasksCompleted.toString(),
                        onChanged: (value) {
                          _tasksCompleted = int.tryParse(value) ?? 0;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Distraction Level slider
                      const Text(
                        'Distraction Level:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _distractionLevel,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _distractionLevel.round().toString(),
                        activeColor: Colors.amber.shade700,
                        onChanged: (value) {
                          setState(() {
                            _distractionLevel = value;
                          });
                        },
                      ),
                       const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Minimal'),
                          Text('Highly Distracted'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Productivity Rating slider
                      const Text(
                        'Productivity Rating:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _productivityRating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _productivityRating.round().toString(),
                        activeColor: Colors.amber.shade700,
                        onChanged: (value) {
                          setState(() {
                            _productivityRating = value;
                          });
                        },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Poor'),
                          Text('Excellent'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Submit button
                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                          onPressed: _submitData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          ),
                          child: const Text(
                            'Save Productivity Data',
                            style: TextStyle(fontSize: 16, color: Colors.white),
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
      ),
    );
  }
}