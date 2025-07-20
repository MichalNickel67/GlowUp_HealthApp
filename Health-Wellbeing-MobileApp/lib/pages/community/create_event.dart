import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

// A page for creating events that allows users to input event details and save them to Firestore
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState(); // Fixed warning by using State<T> instead of private type
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form fields
  String name = '';
  DateTime eventDate = DateTime.now();
  TimeOfDay eventTime = TimeOfDay.now();
  String address = '';
  String postcode = '';
  String category = '';
  int duration = 0;
  double latitude = 0.0;
  double longitude = 0.0;

  // List of wellness categories for dropdown
  final List<String> categories = [
    'Yoga',
    'Meditation',
    'Fitness',
    'Mental Health',
    'Nutrition',
    'Wellness',
    'Mindfulness',
  ];

  void _log(String message) {
    assert(() {
      developer.log(message, name: 'CreateEventPage');
      return true;
    }());
  }

  // Method to submit the form data to Firestore
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Get the user's UID and fetch their name from the 'UserDetails' collection
        User? user = _auth.currentUser;
        if (user == null) {
          // Handle the case if the user is not logged in
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User is not logged in')),
          );
          return;
        }

        String userId = user.uid;
        DocumentSnapshot userDoc = await _firestore.collection('UserDetails').doc(userId).get();

        // Ensure that the user document exists
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Check if 'name' field exists and is not null
          if (userData.containsKey('name') && userData['name'] != null) {
            String userName = userData['name'];

            // Combine address and postcode for geocoding
            String fullAddress = "$address $postcode";

            // Geocoding - Convert address to latitude and longitude
            try {
              List<Location> locations = await locationFromAddress(fullAddress);
              if (locations.isNotEmpty) {
                latitude = locations.first.latitude;
                longitude = locations.first.longitude;

                // Log coordinates
                _log("Latitude: $latitude, Longitude: $longitude");
              } else {
                // Handle the case where geocoding does not return a valid location
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not find location for the provided address')),
                );
                return;
              }
            } catch (e) {
              // Handle geocoding error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error with geocoding: $e')),
              );
              return;
            }

            // Log event data
            _log("Event Data to be written: ");
            _log({
              'name': userName,
              'creatorId': userId,
              'event_name': name,
              'date': eventDate.toIso8601String(),
              'time': eventTime.format(context),
              'address': address,
              'postcode': postcode,
              'category': category,
              'duration': duration,
              'latitude': latitude,
              'longitude': longitude,
            }.toString());

            // Now save the event details to the Firestore 'events' collection and include the user's UID for permission checks
            await _firestore.collection('events').add({
              'name': userName,  // Store the logged-in user's name
              'creatorId': userId, // Store the creator's UID
              'event_name': name,
              'date': eventDate.toIso8601String(),
              'time': eventTime.format(context),
              'address': address,
              'postcode': postcode,
              'category': category,
              'duration': duration,
              'latitude': latitude,
              'longitude': longitude,
              // Store the event's exact start datetime for auto-deletion
              'exactStartTime': DateTime(
                eventDate.year,
                eventDate.month,
                eventDate.day,
                eventTime.hour,
                eventTime.minute,
              ).toIso8601String(),
            });

            // Show a success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event created successfully!')),
            );

            // Navigate back to the previous page or reset the form
            Navigator.pop(context);
          } else {
            // Handle the case where the 'name' field is missing in UserDetails
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User name not found in Firestore')),
            );
          }
        } else {
          // Handle the case where the UserDetails document does not exist
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UserDetails document does not exist')),
          );
        }
      } catch (e) {
        // Handle any errors during form submission
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.normal)),
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/createevent.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title for the form
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24.0),
                            child: Text(
                              'Create Your Wellness Event',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Event Name Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Event Name',
                              prefixIcon: const Icon(Icons.event, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onSaved: (value) => name = value!,
                            validator: (value) => value!.isEmpty ? 'Please enter an event name' : null,
                          ),
                          const SizedBox(height: 16),
                          // Date Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Date (dd/MM/yyyy)',
                              prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onTap: () async {
                              // Show date picker when tapped
                              DateTime? selectedDate = await showDatePicker(
                                context: context,
                                initialDate: eventDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.teal,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (selectedDate != null && selectedDate != eventDate) {
                                setState(() {
                                  eventDate = selectedDate;
                                });
                              }
                            },
                            controller: TextEditingController(text: "${eventDate.day}/${eventDate.month}/${eventDate.year}"),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          // Time Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Time',
                              prefixIcon: const Icon(Icons.access_time, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onTap: () async {
                              // Show time picker when tapped
                              TimeOfDay? selectedTime = await showTimePicker(
                                context: context,
                                initialTime: eventTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.teal,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (selectedTime != null && selectedTime != eventTime) {
                                setState(() {
                                  eventTime = selectedTime;
                                });
                              }
                            },
                            controller: TextEditingController(text: eventTime.format(context)),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          // Address Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Address',
                              prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onSaved: (value) => address = value!,
                            validator: (value) => value!.isEmpty ? 'Please enter an address' : null,
                          ),
                          const SizedBox(height: 16),
                          // Postcode Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Postcode',
                              prefixIcon: const Icon(Icons.mail_outline, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onSaved: (value) => postcode = value!,
                            validator: (value) => value!.isEmpty ? 'Please enter a postcode' : null,
                          ),
                          const SizedBox(height: 16),
                          // Category Dropdown
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: const Icon(Icons.category, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            value: category.isEmpty ? null : category,
                            onChanged: (String? newValue) {
                              setState(() {
                                category = newValue!;
                              });
                            },
                            items: categories.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            validator: (value) => value == null ? 'Please select a category' : null,
                          ),
                          const SizedBox(height: 16),
                          // Duration Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Duration (mins)',
                              prefixIcon: const Icon(Icons.timer, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (value) => duration = int.parse(value!),
                            validator: (value) => value!.isEmpty ? 'Please enter duration' : null,
                          ),
                          const SizedBox(height: 24),
                          // Create Event Button
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Create Event',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}