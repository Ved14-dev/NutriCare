import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
    static Future<void> showPersonalDetailsReminder() async {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'details_channel',
        'Personal Details Reminder',
        channelDescription: 'Reminds user to fill personal details for personalized plans',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        2,
        'Complete your profile!',
        'Fill details for more personalized plans.',
        details,
        payload: 'details_reminder',
      );
    }
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.actionId == 'yes') {
          await NotificationService.incrementHydration();
        }
      },
    );
    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // flutter_local_notifications < 13.0.0 does not support requestPermission, so show a dialog
        // Instruct user to enable notifications manually if needed
        // Optionally, use a package like permission_handler for a better UX
      }
    }
  }

  static Timer? _hydrationTimer;

  static Future<void> scheduleHydrationReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hydration_channel',
      'Hydration Reminders',
      channelDescription: 'Reminds user to drink water',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('yes', 'Yes', showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('no', 'No', showsUserInterface: true, cancelNotification: true),
      ],
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    // Cancel any previous timer
    _hydrationTimer?.cancel();
    // Schedule notification every 2 minutes
    _hydrationTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await _plugin.show(
        1,
        'Did you drink water??',
        'Tap Yes if you did!',
        details,
        payload: 'hydration_yes',
      );
    });
  }

  static Future<void> incrementHydration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('hydration_logs')
        .doc(today);
    final doc = await docRef.get();
    double litres = (doc.data()?['litres'] ?? 0.0) as double;
    await docRef.set({'litres': litres + 0.25}, SetOptions(merge: true)); // Default increment 250ml
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
