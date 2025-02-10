// So now you know how above code works right? use only those dependency which is used in that code
// so please make my code also work below is my code :

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';

// class NotificationService {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // Singleton pattern.
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   /// Initializes the notification service:
//   /// 1. Requests notification permission (and, on Android 13+, the new notification permission).
//   /// 2. Initializes flutter_local_notifications.
//   /// 3. Prints confirmation messages.
//   Future<void> init() async {
//     print('NotificationService init started.');

//     // For Android 13 (SDK 33) and above, you need to request notification permission.
//     if (Platform.isAndroid) {
//       // Request the notification permission.
//       final PermissionStatus status = await Permission.notification.request();
//       print('Notification permission status: $status');
//       if (!status.isGranted) {
//         print('Notification permission not granted.');
//         // Optionally, prompt the user to open app settings.
//         await openAppSettings();
//       }
//     } else {
//       print('Not running on Android - no runtime notification permission needed.');
//     }

//     // Initialize flutter_local_notifications.
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
//     try {
//       await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//       print('FlutterLocalNotificationsPlugin initialized successfully.');
//     } catch (e) {
//       print('Error initializing FlutterLocalNotificationsPlugin: $e');
//       return;
//     }

//     print('Notification service initialization completed.');
//   }

//   /// Schedules a notification for the given [documentId] and [title] at the given [scheduledDate].
//   /// The [scheduledDate] must be in the future.
//   Future<void> scheduleNotification(
//       String documentId, String title, DateTime scheduledDate) async {
//     print(
//         'scheduleNotification called for documentId: $documentId, title: $title, scheduledDate: $scheduledDate');
//     if (scheduledDate.isBefore(DateTime.now())) {
//       print("Scheduled date is in the past. Notification will not be scheduled.");
//       return;
//     }

//     // Generate a unique notification id.
//     // (For example, using the last 6 digits of the documentId)
//     int notifId = int.tryParse(documentId.substring(documentId.length - 6)) ?? 0;
//     print('Generated notification ID: $notifId');

//     // Set up the notification details.
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'document_reminder_channel', // Channel ID.
//       'Document Reminders', // Channel name.
//       channelDescription: 'Reminders for documents', // Channel description.
//       importance: Importance.max,
//       priority: Priority.high,
//       ticker: 'ticker',
//       playSound: true,
//       enableLights: true,
//     );
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);

//     try {
//       // Schedule the notification using the schedule() method.
//       await flutterLocalNotificationsPlugin.schedule(
//         notifId,
//         'Reminder: $title',
//         'Your document "$title" is due soon.',
//         scheduledDate,
//         platformChannelSpecifics,
//         androidAllowWhileIdle: true,
//       );
//       print('Notification scheduled (ID: $notifId) for $scheduledDate');
//     } catch (e) {
//       print('Error scheduling notification: $e');
//     }
//   }
// }
