// Notifications for trackers but not implemented

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<String?> onNotificationClick = BehaviorSubject();

  NotificationService._internal();

  Future<void> initNotification() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
          onNotificationClick.add(payload);
        }
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        onNotificationClick.add(notificationResponse.payload);
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'channel_id',
      'GlowUp Reminders',
      channelDescription: 'Channel for GlowUp app reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'channel_id',
      'GlowUp Reminders',
      channelDescription: 'Channel for GlowUp app reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> scheduleReminderNotifications() async {
    await cancelAllNotifications(); // Clear existing notifications first

    // Schedule notifications for each tracker
    await _scheduleTrackerNotification('sleep', 'Sleep Tracker Reminder', 'Don\'t forget to log your sleep for today!', 10, 0);
    await _scheduleTrackerNotification('exercise', 'Exercise Tracker Reminder', 'Have you logged your exercise activity today?', 18, 0);
    await _scheduleTrackerNotification('meditation', 'Meditation Tracker Reminder', 'Take a moment to log your meditation practice today', 15, 0);
    await _scheduleTrackerNotification('productivity', 'Productivity Tracker Reminder', 'Track your productivity for today!', 19, 30);
    await _scheduleTrackerNotification('nutrition', 'Nutrition Tracker Reminder', 'Don\'t forget to log your meals for today!', 20, 0);
  }

  Future<void> _scheduleTrackerNotification(String trackerType, String title, String body, int hour, int minute) async {
    // Check if the user has already completed this tracker today
    if (!await _hasCompletedTrackerToday(trackerType)) {
      // Calculate notification time for today
      final now = DateTime.now();
      DateTime scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Schedule the notification
      await scheduleNotification(
        id: _getNotificationIdForTracker(trackerType),
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: trackerType,
      );
    }
  }

  int _getNotificationIdForTracker(String trackerType) {
    // Return a unique ID for each tracker type
    switch (trackerType) {
      case 'sleep': return 1;
      case 'exercise': return 2;
      case 'meditation': return 3;
      case 'productivity': return 4;
      case 'nutrition': return 5;
      default: return 0;
    }
  }

  Future<bool> _hasCompletedTrackerToday(String trackerType) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final today = DateTime.now();
    final dateString = '${today.year}-${today.month}-${today.day}';

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('userTracking')
          .doc(user.uid)
          .collection(trackerType)
          .doc(dateString)
          .get();

      return docSnapshot.exists;
    } catch (e) {
      print('Error checking if tracker completed: $e');
      return false;
    }
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Call this method when a tracker is completed
  Future<void> trackerCompleted(String trackerType) async {
    // Cancel the specific notification for this tracker
    await cancelNotification(_getNotificationIdForTracker(trackerType));

    // Store completion status
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateString = '${today.year}-${today.month}-${today.day}';

    // This is just to mark that the tracker was completed today
    // The actual tracker data would be stored in your tracker pages
    try {
      await FirebaseFirestore.instance
          .collection('userTracking')
          .doc(user.uid)
          .collection(trackerType)
          .doc(dateString)
          .set({'completed': true, 'timestamp': DateTime.now()});
    } catch (e) {
      print('Error marking tracker as completed: $e');
    }
  }
}