import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Exercise Tracker Page widget to track and record workouts
class ExerciseTrackerPage extends StatefulWidget {
  const ExerciseTrackerPage({super.key});

  @override
  State<ExerciseTrackerPage> createState() => ExerciseTrackerPageState();
}

class ExerciseTrackerPageState extends State<ExerciseTrackerPage> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  DateTime _date = DateTime.now();
  String _exerciseType = 'Running';
  int _duration = 30;
  double _distance = 0.0;
  int _steps = 0;
  int _caloriesBurned = 0;
  double _intensity = 3.0;

  // Controllers for real-time updates
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _intensityController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _recentEntries = [];

  // List of available exercise types
  final List<String> _exerciseTypes = [
    'Running',
    'Walking',
    'Cycling',
    'Swimming',
    'Strength Training',
    'Yoga',
    'HIIT',
    'Pilates',
    'Dance',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _durationController.text = _duration.toString();
    _loadRecentEntries();
  }

  // Loads recent exercise entries from Firestore
  Future<void> _loadRecentEntries() async {
    if (user == null) return;

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ExerciseTracker')
          .doc(user!.uid)
          .collection('exercise_tracker')
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

  // Displays date picker and updates selected date
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

  bool _showDistance() {
    return ['Running', 'Walking', 'Cycling'].contains(_exerciseType);
  }
  bool _showSteps() {
    return ['Running', 'Walking'].contains(_exerciseType);
  }

  // Calculates calories burned based on exercise type, duration and intensity
  void _calculateCalories() {
    double weight = 70.0;
    double baseCalories = 0;

    switch (_exerciseType) {
      case 'Running':
        baseCalories = 0.063 * weight * _duration; // Formula for running
        break;
      case 'Walking':
        baseCalories = 0.045 * weight * _duration; // Formula for walking
        break;
      case 'Cycling':
        baseCalories = 0.049 * weight * _duration; // Formula for cycling
        break;
      default:
        baseCalories = 0.035 * weight * _duration; // Default generic formula
        break;
    }

    // Adjust calories based on intensity (1-5 scale)
    _caloriesBurned = (baseCalories * (_intensity / 3)).toInt();
    _caloriesController.text = _caloriesBurned.toString();
  }

  // Automatically calculate steps based on distance for running/walking
  void _calculateSteps() {
    const int stepsPerKm = 1250; // Average steps per kilometer for running/walking
    if (_showSteps()) {
      _steps = (_distance * stepsPerKm).toInt();
      _stepsController.text = _steps.toString();
    }
  }

  // Updates both calories and steps calculations
  void _updateCalculations() {
    _calculateCalories();
    _calculateSteps();
  }

  // Submits exercise data to Firestore
  Future<void> _submitData() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit data')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Calculate calories and steps before submitting
      _updateCalculations();

      setState(() {
        _isLoading = true;
      });

      try {
        // Create exercise data map for Firestore
        Map<String, dynamic> exerciseData = {
          'date': Timestamp.fromDate(_date),
          'exerciseType': _exerciseType,
          'duration': _duration,
          'intensity': _intensity,
          'caloriesBurned': _caloriesBurned,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (_showDistance()) {
          exerciseData['distance'] = _distance;
        }

        if (_showSteps()) {
          exerciseData['steps'] = _steps;
        }

        // Create a unique document ID using date and timestamp
        String docId = '${DateFormat('yyyy-MM-dd').format(_date)}-${DateTime.now().millisecondsSinceEpoch}';

        // Save data to Firestore
        await FirebaseFirestore.instance
            .collection('ExerciseTracker')
            .doc(user!.uid)
            .collection('exercise_tracker')
            .doc(docId)
            .set(exerciseData);

        // Reset form after successful submission
        setState(() {
          _exerciseType = 'Running';
          _duration = 30;
          _durationController.text = '30';
          _distance = 0.0;
          _distanceController.text = '';
          _steps = 0;
          _stepsController.text = '';
          _caloriesBurned = 0;
          _caloriesController.text = '';
          _intensity = 3.0;
        });

        // Reload the recent entries list
        _loadRecentEntries();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise data saved successfully!')),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
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
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _intensityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Tracker'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                          'Track Your Exercise',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          title: const Text('Date'),
                          subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(_date)),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDate(context),
                        ),

                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Exercise Type',
                            border: OutlineInputBorder(),
                          ),
                          value: _exerciseType,
                          items: _exerciseTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _exerciseType = newValue!;
                              _updateCalculations(); // Recalculate on exercise type change
                            });
                          },
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration (minutes)',
                            border: OutlineInputBorder(),
                            suffixText: 'min',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _duration = int.tryParse(value) ?? 0;
                            _updateCalculations(); // Recalculate on duration change
                          },
                        ),

                        if (_showDistance()) ...[
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _distanceController,
                            decoration: const InputDecoration(
                              labelText: 'Distance (kilometers)',
                              border: OutlineInputBorder(),
                              suffixText: 'km',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              _distance = double.tryParse(value) ?? 0.0;
                              _updateCalculations(); // Recalculate on distance change
                            },
                          ),
                        ],

                        if (_showSteps()) ...[
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _stepsController,
                            decoration: const InputDecoration(
                              labelText: 'Steps',
                              border: OutlineInputBorder(),
                              hintText: 'Auto-calculated',
                            ),
                            keyboardType: TextInputType.number,
                            // Steps field is typically read-only as it's auto-calculated
                            readOnly: true,
                          ),
                        ],

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _caloriesController,
                          decoration: const InputDecoration(
                            labelText: 'Calories Burned',
                            border: OutlineInputBorder(),
                            suffixText: 'kcal',
                            hintText: 'Auto-calculated',
                          ),
                          keyboardType: TextInputType.number,
                          // Calories field is typically read-only as it's auto-calculated
                          readOnly: true,
                        ),

                        const SizedBox(height: 16),
                        const Text('Intensity:', style: TextStyle(fontSize: 16)),
                        Slider(
                          value: _intensity,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _intensity.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _intensity = value;
                              _updateCalculations();
                            });
                          },
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                            onPressed: _submitData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            ),
                            child: const Text(
                              'Save Exercise Data',
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
      ),
    );
  }
}