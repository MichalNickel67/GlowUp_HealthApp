import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Meditation tracker page allowing users to log meditation sessions
class MeditationTrackerPage extends StatefulWidget {
  const MeditationTrackerPage({super.key});

  @override
  State<MeditationTrackerPage> createState() => _MeditationTrackerPageState();
}

class _MeditationTrackerPageState extends State<MeditationTrackerPage> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  DateTime _date = DateTime.now();
  int _duration = 10; // in minutes
  String _meditationType = 'Mindfulness';
  double _focus = 3.0; // 1-5 scale
  double _moodImprovement = 3.0; // 1-5 scale

  bool _isLoading = false;

  // List of meditation types to choose from
  final List<String> _meditationTypes = [
    'Mindfulness',
    'Loving-kindness',
    'Body Scan',
    'Breath Awareness',
    'Visualisation',
    'Mantra',
    'Transcendental',
    'Zen',
    'Yoga Nidra',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
  }

  // Select date for the meditation session
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
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

  // Submit meditation data to Firestore
  Future<void> _submitData() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit data')),
      );
      return;
    }

    // Ensure the user is authenticated
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Create data object for Firestore
        Map<String, dynamic> meditationData = {
          'date': Timestamp.fromDate(_date),
          'duration': _duration,
          'meditationType': _meditationType,
          'focus': _focus,
          'moodImprovement': _moodImprovement,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Generate a unique document ID for each session
        String docId = '${DateFormat('yyyy-MM-dd').format(_date)}-${DateTime.now().millisecondsSinceEpoch}';

        // Save to Firestore under MeditationTracker/{userId}/meditation_tracker/{docId}
        await FirebaseFirestore.instance
            .collection('MeditationTracker')
            .doc(user!.uid) // Document for the logged-in user
            .collection('meditation_tracker') // Where meditation sessions are stored
            .doc(docId) // Document ID for the session
            .set(meditationData);

        // Reset form fields after submission
        setState(() {
          _duration = 10;
          _meditationType = 'Mindfulness';
          _focus = 3.0;
          _moodImprovement = 3.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meditation session saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
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
        title: const Text('Meditation Tracker'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),

            // Meditation tracker form
            Form(
              key: _formKey,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Track Your Meditation',
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

                      // Meditation type dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Meditation Type',
                          border: OutlineInputBorder(),
                        ),
                        value: _meditationType,
                        items: _meditationTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _meditationType = newValue!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Duration in minutes
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(),
                          suffixText: 'min',
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _duration.toString(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _duration = int.tryParse(value) ?? 0;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Focus rating
                      const Text(
                        'Focus Level:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _focus,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _focus.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _focus = value;
                          });
                        },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Distracted'),
                          Text('Fully Present'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Mood improvement slider
                      const Text(
                        'Mood Improvement Level:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _moodImprovement,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _moodImprovement.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _moodImprovement = value;
                          });
                        },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('No improvement'),
                          Text('Significant improvement'),
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
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          ),
                          child: const Text(
                            'Save Meditation Session',
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