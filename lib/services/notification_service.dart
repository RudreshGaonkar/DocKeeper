import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

    final InitializationSettings settings = InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(settings);
    
  }

  static Future<void> scheduleNotification(
      String documentId, String title, DateTime scheduledDate) async {
    tz.initializeTimeZones();
    await _notificationsPlugin.zonedSchedule(
      documentId.hashCode,
      title,
      'Your $title document expires soon.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

   /// Updates a scheduled notification by canceling the old one and scheduling a new one.
  static Future<void> updateNotification(
      String documentId, String title, DateTime newScheduledDate) async {
    int notifId = documentId.hashCode;
    // Cancel the old notification.
    await _notificationsPlugin.cancel(notifId);
    print('Canceled previous notification (ID: $notifId)');
    // Schedule the new notification.
    await scheduleNotification(documentId, title, newScheduledDate);
  }

  static Future<void> showInstantNotification(String title, String body) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'Instant Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }
}
