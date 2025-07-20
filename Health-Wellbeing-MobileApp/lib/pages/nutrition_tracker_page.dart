import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Nutrition tracker page allowing users to log meals and hydration
class NutritionTrackerPage extends StatefulWidget {
  const NutritionTrackerPage({super.key});

  @override
  State<NutritionTrackerPage> createState() => _NutritionTrackerPageState();
}

class _NutritionTrackerPageState extends State<NutritionTrackerPage> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  DateTime _date = DateTime.now();
  String _mealType = 'Breakfast';
  int? _calories;
  double? _protein;
  double? _carbohydrates;
  double? _fats;
  double _nutritionalValue = 3.0; // 1-5 scale
  double _liquidConsumption = 0.0; // Litres
  String _liquidType = 'Water';
  double _hydrationValue = 3.0; // 1-5 scale
  bool _isLoading = false;

  // Dropdown options
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  final List<String> _liquidTypes = ['Water', 'Tea', 'Coffee', 'Juice', 'Energy Drink', 'Other'];

  // Select date using DatePicker widget
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

  // Submit nutrition data to Firestore
  Future<void> _submitData() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
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
        // Create data object for Firestore
        Map<String, dynamic> nutritionData = {
          'date': Timestamp.fromDate(_date),
          'mealType': _mealType,
          'nutritionalValue': _nutritionalValue,
          'liquidConsumption': _liquidConsumption,
          'liquidType': _liquidType,
          'hydrationValue': _hydrationValue,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Optional values
        if (_calories != null) nutritionData['calories'] = _calories;
        if (_protein != null) nutritionData['protein'] = _protein;
        if (_carbohydrates != null) nutritionData['carbohydrates'] = _carbohydrates;
        if (_fats != null) nutritionData['fats'] = _fats;

        // Generate a unique document ID
        String docId = '${DateFormat('yyyy-MM-dd').format(_date)}-${DateTime.now().millisecondsSinceEpoch}';

        // Firebase document path: NutritionTracker/{userId}/entries/{docId}
        await FirebaseFirestore.instance
            .collection('NutritionTracker')
            .doc(user!.uid)
            .collection('entries')
            .doc(docId)
            .set(nutritionData);

        // Reset form fields
        setState(() {
          _mealType = 'Breakfast';
          _calories = null;
          _protein = null;
          _carbohydrates = null;
          _fats = null;
          _nutritionalValue = 3.0;
          _liquidConsumption = 0.0;
          _liquidType = 'Water';
          _hydrationValue = 3.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nutrition entry saved successfully!')),
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
        title: const Text('Nutrition Tracker'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Form(
                key: _formKey,
                child: Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Track Your Nutrition',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date selection using ListTile
                        ListTile(
                          title: const Text('Date'),
                          subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(_date)),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDate(context),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),

                        const SizedBox(height: 10),

                        // Meal Type Dropdown
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Meal Type',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          value: _mealType,
                          items: _mealTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _mealType = newValue!;
                            });
                          },
                        ),

                        const SizedBox(height: 10),

                        // Nutrition inputs
                        Row(
                          children: [
                            // Calories Input
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Calories',
                                  border: OutlineInputBorder(),
                                  suffixText: 'kcal',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                style: const TextStyle(fontSize: 14),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _calories = int.tryParse(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Protein Input
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Protein',
                                  border: OutlineInputBorder(),
                                  suffixText: 'g',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                style: const TextStyle(fontSize: 14),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _protein = double.tryParse(value);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            // Carbohydrates Input
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Carbohydrates',
                                  border: OutlineInputBorder(),
                                  suffixText: 'g',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                style: const TextStyle(fontSize: 14),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _carbohydrates = double.tryParse(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Fats Input
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Fats',
                                  border: OutlineInputBorder(),
                                  suffixText: 'g',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                style: const TextStyle(fontSize: 14),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _fats = double.tryParse(value);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Nutritional Value Slider
                        const Text('Nutritional Value:'),
                        Slider(
                          value: _nutritionalValue,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _nutritionalValue.round().toString(),
                          activeColor: Colors.red,
                          onChanged: (value) {
                            setState(() {
                              _nutritionalValue = value;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Liquid Section
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Liquid Amount',
                                  border: OutlineInputBorder(),
                                  suffixText: 'L',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                style: const TextStyle(fontSize: 14),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) {
                                  _liquidConsumption = double.tryParse(value) ?? 0.0;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Liquid type
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Liquid Type',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                value: _liquidType,
                                items: _liquidTypes.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _liquidType = newValue!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Hydration Value Slider
                        const Text('Hydration Value:'),
                        Slider(
                          value: _hydrationValue,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _hydrationValue.round().toString(),
                          activeColor: Colors.red,
                          onChanged: (value) {
                            setState(() {
                              _hydrationValue = value;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Submit Button
                        Center(
                          child: _isLoading
                              ? const SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                              : ElevatedButton(
                            onPressed: _submitData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            ),
                            child: const Text(
                              'Save Nutrition Data',
                              style: TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom spacing
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}