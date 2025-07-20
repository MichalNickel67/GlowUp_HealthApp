import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'create_event.dart';

// UpcomingEventsPage displays a map with event markers and a list of upcoming events
class UpcomingEventsPage extends StatefulWidget {
  const UpcomingEventsPage({super.key});

  @override
  State<UpcomingEventsPage> createState() => _UpcomingEventsPageState();
}

class _UpcomingEventsPageState extends State<UpcomingEventsPage> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getCurrentUser();
    _deleteExpiredEvents().then((_) => _fetchEvents());

    // Set up a timer to check for expired events more frequently (every 15 minutes)
    Timer.periodic(const Duration(minutes: 15), (timer) {
      _deleteExpiredEvents().then((_) => _fetchEvents());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _deleteExpiredEvents().then((_) => _fetchEvents());
    }
  }

  // Get the current logged-in user
  void _getCurrentUser() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  // Fetch events from Firestore
  Future<void> _fetchEvents() async {
    // Get all documents from the events collection
    QuerySnapshot snapshot = await _firestore.collection('events').get();

    setState(() {
      _markers = {};  // Clear existing markers

      // Process each event document
      for (var doc in snapshot.docs) {
        // Get the document data
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        // Skip if no data
        if (data == null) continue;

        // Check if latitude and longitude exist directly in the document
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          _addMarker(doc.id, data);
        }
      }
    });
  }

  // Delete expired events automatically - improved to check exact start time
  Future<void> _deleteExpiredEvents() async {
    try {
      // Get the current date and time
      final now = DateTime.now();

      // Query events that have passed (both by date and time)
      QuerySnapshot expiredEventsQuery;

      // First attempt to use exactStartTime for precise filtering
      expiredEventsQuery = await _firestore.collection('events')
          .where('exactStartTime', isLessThan: now.toIso8601String())
          .get();

      // If exactStartTime field doesn't exist in some documents, fallback to date-only check
      if (expiredEventsQuery.docs.isEmpty) {
        final today = DateTime(now.year, now.month, now.day);
        expiredEventsQuery = await _firestore.collection('events')
            .where('date', isLessThan: today.toIso8601String())
            .get();
      }

      if (expiredEventsQuery.docs.isNotEmpty) {
        // Use a batch to delete multiple documents efficiently
        final batch = _firestore.batch();
        bool hasPendingChanges = false;

        // For each expired event document
        for (var doc in expiredEventsQuery.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Check if exactStartTime exists and is valid
          if (data.containsKey('exactStartTime')) {
            try {
              DateTime eventStartTime = DateTime.parse(data['exactStartTime']);

              // Only delete if the event start time has passed
              if (eventStartTime.isBefore(now)) {
                batch.delete(doc.reference);
                hasPendingChanges = true;
              }
            } catch (e) {
              developer.log('Error parsing exactStartTime: $e', name: 'UpcomingEventsPage');

              // Fallback to date and time fields if exactStartTime parsing fails
              try {
                DateTime eventDate = DateTime.parse(data['date']);
                String timeStr = data['time'] ?? '';

                // Parse time string (format: 'HH:MM AM/PM')
                TimeOfDay? eventTime = _parseTimeString(timeStr);

                // If we could parse both date and time
                if (eventTime != null) {
                  // Combine date and time into a single DateTime
                  DateTime eventStartTime = DateTime(
                    eventDate.year,
                    eventDate.month,
                    eventDate.day,
                    eventTime.hour,
                    eventTime.minute,
                  );

                  // Only delete if the event start time has passed
                  if (eventStartTime.isBefore(now)) {
                    batch.delete(doc.reference);
                    hasPendingChanges = true;
                  }
                } else {
                  // If time couldn't be parsed, fall back to date-only check
                  if (eventDate.isBefore(DateTime(now.year, now.month, now.day))) {
                    batch.delete(doc.reference);
                    hasPendingChanges = true;
                  }
                }
              } catch (dateError) {
                developer.log('Error parsing event date: $dateError', name: 'UpcomingEventsPage');
                // If all parsing fails, delete the document to avoid orphaned events
                batch.delete(doc.reference);
                hasPendingChanges = true;
              }
            }
          } else {
            // Handle older event format without exactStartTime
            try {
              DateTime eventDate = DateTime.parse(data['date']);
              String timeStr = data['time'] ?? '';

              // Parse time string (format: 'HH:MM AM/PM')
              TimeOfDay? eventTime = _parseTimeString(timeStr);

              // If we could parse both date and time
              if (eventTime != null) {
                // Combine date and time into a single DateTime
                DateTime eventStartTime = DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                  eventTime.hour,
                  eventTime.minute,
                );

                // Only delete if the event start time has passed
                if (eventStartTime.isBefore(now)) {
                  batch.delete(doc.reference);
                  hasPendingChanges = true;
                }
              } else {
                if (eventDate.isBefore(DateTime(now.year, now.month, now.day))) {
                  batch.delete(doc.reference);
                  hasPendingChanges = true;
                }
              }
            } catch (e) {
              developer.log('Error parsing event date/time: $e', name: 'UpcomingEventsPage');
              batch.delete(doc.reference);
              hasPendingChanges = true;
            }
          }
        }
        if (hasPendingChanges) {
          await batch.commit();
          developer.log('Deleted expired events', name: 'UpcomingEventsPage');
          _fetchEvents();
        }
      }
    } catch (e) {
      developer.log('Error deleting expired events: $e', name: 'UpcomingEventsPage', error: e);
    }
  }

  // Helper method to change time string (format: 'HH:MM AM/PM')
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      // Handle different time formats
      if (timeStr.contains(':')) {
        List<String> parts = timeStr.split(':');
        int hour = int.parse(parts[0].trim());

        // Handle second part which might contain minutes and AM/PM
        String minutePart = parts[1].trim();
        int minute = 0;

        if (minutePart.contains(' ')) {
          // Format like "7:30 PM"
          List<String> minuteAndPeriod = minutePart.split(' ');
          minute = int.parse(minuteAndPeriod[0]);

          // Adjust hour for PM
          if (minuteAndPeriod[1].toUpperCase() == 'PM' && hour < 12) {
            hour += 12;
          }
          // Adjust hour for AM
          if (minuteAndPeriod[1].toUpperCase() == 'AM' && hour == 12) {
            hour = 0;
          }
        } else {
          // Format like "19:30"
          minute = int.parse(minutePart);
        }

        return TimeOfDay(hour: hour, minute: minute);
      }

      return null;
    } catch (e) {
      developer.log('Error parsing time string: $e', name: 'UpcomingEventsPage');
      return null;
    }
  }

  // Adds a marker to the map for an event
  void _addMarker(String documentId, Map<String, dynamic> data) {
    // Check if latitude and longitude are valid
    if (data['latitude'] == null || data['longitude'] == null) return;

    // Format the date to format (DD/MM/YYYY)
    DateTime? eventDate;
    try {
      eventDate = DateTime.parse(data['date']);
    } catch (e) {
      developer.log('Error parsing date: $e', name: 'UpcomingEventsPage');
      return;
    }

    String formattedDate = '${eventDate.day.toString().padLeft(2, '0')}/${eventDate.month.toString().padLeft(2, '0')}/${eventDate.year}';
    String category = data['category'] ?? 'Other';

    // Create Marker for the event
    final marker = Marker(
      markerId: MarkerId(documentId),
      position: LatLng(data['latitude'], data['longitude']),
      infoWindow: InfoWindow(
        title: data['event_name'] ?? 'Unnamed Event',
        snippet: "$category | $formattedDate | ${data['time'] ?? 'TBA'}",
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(_getCategoryColor(category)),
    );

    // Add the marker
    _markers.add(marker);
  }

  // Get a colour based on the category
  double _getCategoryColor(String category) {
    switch(category.toLowerCase()) {
      case 'yoga':
        return BitmapDescriptor.hueViolet;
      case 'meditation':
        return BitmapDescriptor.hueBlue;
      case 'fitness':
        return BitmapDescriptor.hueRed;
      case 'mental health':
        return BitmapDescriptor.hueGreen;
      case 'nutrition':
        return BitmapDescriptor.hueOrange;
      case 'wellness':
        return BitmapDescriptor.hueCyan;
      case 'mindfulness':
        return BitmapDescriptor.hueRose;
      default:
        return BitmapDescriptor.hueYellow;
    }
  }

  // Delete an event
  Future<void> _deleteEvent(String eventId, String? creatorId) async {
    // Check if user is logged in
    if (_currentUserId == null) {
      _showErrorSnackBar('You must be logged in to delete events');
      return;
    }

    // Check if the current user is the creator of this event
    if (creatorId != null && creatorId != _currentUserId) {
      _showErrorSnackBar('You can only delete events you created');
      return;
    }

    // Show confirmation dialog
    bool confirmDelete = await _showDeleteConfirmationDialog() ?? false;

    if (confirmDelete) {
      try {
        // Delete the event from Firestore
        await _firestore.collection('events').doc(eventId).delete();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully'))
        );

        // Refresh events
        _fetchEvents();
      } catch (e) {
        developer.log('Error deleting event: $e', name: 'UpcomingEventsPage', error: e);
        _showErrorSnackBar('Failed to delete event: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(message),
        )
    );
  }

  // Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Events')),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(51.5074, -0.1278), // Default coordinates
                zoom: 12,
              ),
              markers: _markers, // Set the markers for the map
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('events').orderBy('date').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No upcoming events."));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                    // Format the date for display in format (DD/MM/YYYY)
                    DateTime eventDate;
                    String formattedDate = 'Date TBA';

                    try {
                      eventDate = DateTime.parse(data['date']);
                      formattedDate = '${eventDate.day.toString().padLeft(2, '0')}/${eventDate.month.toString().padLeft(2, '0')}/${eventDate.year}';
                    } catch (e) {
                      developer.log('Error parsing date: $e', name: 'UpcomingEventsPage');
                    }

                    // Get creator ID
                    String? creatorId = data['creatorId'];

                    return _eventCard(data, formattedDate, doc.id, creatorId);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Event',
        onPressed: () {
          // Check if user is logged in before allowing event creation
          if (_currentUserId == null) {
            _showErrorSnackBar('You must be logged in to create events');
            return;
          }

          // Navigate to CreateEventPage when the button is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventPage()),
          ).then((_) {
            _fetchEvents();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Creates a card widget for an event
  Widget _eventCard(Map<String, dynamic> data, String formattedDate, String docId, String? creatorId) {
    String category = data['category'] ?? 'Other';

    // Check if the current user is the creator of this event
    bool isCreator = creatorId != null && _currentUserId != null && creatorId == _currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: _getCategoryBorderColor(category), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              color: _getCategoryBorderColor(category).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getCategoryBorderColor(category),
                  ),
                ),
                // Make delete button for creator
                if (isCreator)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(60, 24),
                    ),
                    onPressed: () => _deleteEvent(docId, creatorId),
                    icon: const Icon(Icons.delete, color: Colors.white, size: 16),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          // Event details
          ListTile(
            title: Text(
              data['event_name'] ?? 'Unnamed Event',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "$formattedDate | ${data['time'] ?? 'Time TBA'}\n📍 ${data['address'] ?? 'No address'} (${data['postcode'] ?? 'No postcode'})",
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${data['duration'] ?? '?'} mins",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isCreator)
                  const Text(
                    "You created this",
                    style: TextStyle(fontSize: 10, color: Colors.blue),
                  ),
              ],
            ),
            onTap: () {
              // Center the map on this location when tapped
              if (data['latitude'] != null && data['longitude'] != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(LatLng(data['latitude'], data['longitude'])),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Get a colour for card border based on category
  Color _getCategoryBorderColor(String category) {
    switch(category.toLowerCase()) {
      case 'yoga':
        return Colors.purple;
      case 'meditation':
        return Colors.indigo;
      case 'fitness':
        return Colors.red;
      case 'mental health':
        return Colors.green;
      case 'nutrition':
        return Colors.orange;
      case 'wellness':
        return Colors.teal;
      case 'mindfulness':
        return Colors.pink;
      default:
        return Colors.amber;
    }
  }
}