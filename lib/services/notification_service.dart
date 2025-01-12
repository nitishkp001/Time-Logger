import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:time_logger3/services/navigation_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('app_icon');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    // Request permissions right after initialization
    await requestPermissions();
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation == null) {
        debugPrint('Failed to get Android implementation');
        return false;
      }

      try {
        final bool? granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      } catch (e) {
        debugPrint('Error requesting notification permissions: $e');
        return false;
      }
    }
    return false;
  }

  Future<void> scheduleDailyTaskReminder(
      int id, String title, String body) async {
    try {
      await requestPermissions();

      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        8, // 8 AM
        0,
      );

      // If it's already past 8 AM, schedule for next day
      if (now.hour >= 8) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'daily_tasks',
        'Daily Tasks',
        channelDescription: 'Notifications for daily tasks',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (e) {
      debugPrint('Failed to schedule notification: ${e.message}');
      // Handle the error gracefully - maybe show a snackbar to the user
      if (NavigationService.navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(NavigationService.navigatorKey.currentContext!)
            .showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to schedule notification. Please check app permissions.'),
          ),
        );
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

extension on AndroidFlutterLocalNotificationsPlugin {
  requestPermissions() {}
}
