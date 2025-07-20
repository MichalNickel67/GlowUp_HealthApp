import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Sleep Tracker page that allows users to log and visualise their sleep data
// This widget handles recording sleep times, quality ratings, and displays recent entries
class SleepTrackerPage extends StatefulWidget {
  const SleepTrackerPage({super.key});

  @override
  State<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  DateTime _date = DateTime.now();
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  double _sleepQuality = 3.0;

  bool _isLoading = false;
  List<Map<String, dynamic>> _recentEntries = [];

  @override
  void initState() {
    super.initState();
    _loadRecentEntries();
  }

  // Loads the most recent sleep entries from Firestore
  // Retrieves up to 5 entries sorted by date (newest first)
  Future<void> _loadRecentEntries() async {
    if (user == null) return;

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('SleepTracker')
          .doc(user!.uid)
          .collection('sleep_tracker')
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      setState(() {
        _recentEntries = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recent entries: $e')),
        );
      }
    }
  }

  // Opens a date picker to select sleep date
  Future<void> _selectDate(BuildContext context) async {
    final currentContext = context;
    final DateTime? picked = await showDatePicker(
      context: currentContext,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _date && mounted) {
      setState(() {
        _date = picked;
      });
    }
  }

  // Opens a time picker to select bedtime
  Future<void> _selectBedTime(BuildContext context) async {
    final currentContext = context;
    final TimeOfDay? picked = await showTimePicker(
      context: currentContext,
      initialTime: _bedTime,
    );
    if (picked != null && picked != _bedTime && mounted) {
      setState(() {
        _bedTime = picked;
      });
    }
  }

  // Opens a time picker to select wake time
  Future<void> _selectWakeTime(BuildContext context) async {
    final currentContext = context;
    final TimeOfDay? picked = await showTimePicker(
      context: currentContext,
      initialTime: _wakeTime,
    );
    if (picked != null && picked != _wakeTime && mounted) {
      setState(() {
        _wakeTime = picked;
      });
    }
  }

  // Calculates sleep duration in minutes
  int _calculateSleepDuration() {
    int bedTimeMinutes = _bedTime.hour * 60 + _bedTime.minute;
    int wakeTimeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;

    int durationMinutes;
    if (wakeTimeMinutes < bedTimeMinutes) {
      durationMinutes = (24 * 60 - bedTimeMinutes) + wakeTimeMinutes;
    } else {
      durationMinutes = wakeTimeMinutes - bedTimeMinutes;
    }

    return durationMinutes;
  }

  // Submits sleep data to Firestore by creating or updating a document with the date as ID
  Future<void> _submitData() async {
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to submit data')),
        );
      }
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        int durationMinutes = _calculateSleepDuration();
        String durationFormatted =
            '${(durationMinutes / 60).floor()}h ${durationMinutes % 60}m';

        Map<String, dynamic> sleepData = {
          'date': Timestamp.fromDate(_date),
          'bedTime': '${_bedTime.hour}:${_bedTime.minute.toString().padLeft(2, '0')}',
          'wakeTime': '${_wakeTime.hour}:${_wakeTime.minute.toString().padLeft(2, '0')}',
          'durationMinutes': durationMinutes,
          'durationFormatted': durationFormatted,
          'sleepQuality': _sleepQuality,
          'createdAt': FieldValue.serverTimestamp(),
        };

        String docId = DateFormat('yyyy-MM-dd').format(_date);

        await FirebaseFirestore.instance
            .collection('SleepTracker')
            .doc(user!.uid)
            .collection('sleep_tracker')
            .doc(docId)
            .set(sleepData);

        setState(() {
          _date = DateTime.now();
          _sleepQuality = 3.0;
        });

        _loadRecentEntries();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sleep data saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving data: $e')),
          );
        }
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
        title: const Text('Sleep Tracker'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Sleep tracking form card
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
                        'Track Your Sleep',
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

                      // Bed time selection
                      ListTile(
                        title: const Text('Bed Time'),
                        subtitle: Text(_bedTime.format(context)),
                        trailing: const Icon(Icons.bedtime),
                        onTap: () => _selectBedTime(context),
                      ),

                      // Wake time selection
                      ListTile(
                        title: const Text('Wake Time'),
                        subtitle: Text(_wakeTime.format(context)),
                        trailing: const Icon(Icons.wb_sunny),
                        onTap: () => _selectWakeTime(context),
                      ),

                      // Sleep duration display
                      ListTile(
                        title: const Text('Sleep Duration'),
                        subtitle: Text(() {
                          int mins = _calculateSleepDuration();
                          int hours = (mins / 60).floor();
                          int minutes = mins % 60;
                          return '$hours hours $minutes minutes';
                        }()),
                        trailing: const Icon(Icons.access_time),
                      ),

                      const Divider(),

                      // Sleep quality slider
                      const Text(
                        'Sleep Quality:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _sleepQuality,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _sleepQuality.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _sleepQuality = value;
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
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          ),
                          child: const Text(
                            'Save Sleep Data',
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