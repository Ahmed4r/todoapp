import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';
import 'notification_background_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<bool> requestIOSPermissions() async {
    final iOS = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iOS == null) return false;

    try {
      final result = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
        provisional: true,
      );

      debugPrint('iOS permissions request result: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting iOS permissions: $e');
      return false;
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    try {
      final hasPermission =
          await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.canScheduleExactNotifications() ??
          false;

      if (hasPermission) {
        debugPrint('Already has exact alarm permission');
        return true;
      }

      // For Android 12 and above
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final result = await androidImplementation
            .requestExactAlarmsPermission();
        debugPrint('Exact alarm permission request result: $result');
        return result ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
    }

    return false;
  }

  Future<void> initialize() async {
    debugPrint('Initializing NotificationService...');

    try {
      // Initialize timezone
      try {
        // Try to get a standard timezone name that the timezone package recognizes
        // We'll use Europe/Istanbul as a fallback for EEST (Eastern European Summer Time)
        final now = DateTime.now();
        final timeZoneName = now.timeZoneName == 'EEST'
            ? 'Europe/Istanbul'
            : 'UTC';
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('Local timezone set to: $timeZoneName');
      } catch (e) {
        debugPrint('Error setting timezone: $e');
        tz.setLocalLocation(tz.getLocation('UTC'));
        debugPrint('Fallback to UTC timezone');
      }

      // Request permissions for iOS
      final hasIOSPermissions = await requestIOSPermissions();
      debugPrint('Has iOS permissions: $hasIOSPermissions');

      // Request exact alarm permission for Android
      final hasExactAlarmPermission = await requestExactAlarmPermission();
      debugPrint('Has exact alarm permission: $hasExactAlarmPermission');

      const iOSSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // We'll request this manually
        requestBadgePermission: false, // We'll request this manually
        requestSoundPermission: false, // We'll request this manually
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      );

      // Initialize plugin with background handler
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
          // Handle notification click in foreground
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      debugPrint('NotificationPlugin initialized');

      // Request permissions for iOS
      final iOS = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iOS != null) {
        final result = await iOS.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('iOS permissions requested. Result: $result');
      }

      // Check Android permissions
      final android = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        debugPrint('Android permission granted: $granted');
      }

      debugPrint('Initialization complete.');
    } catch (e, stack) {
      debugPrint('Error initializing notifications: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  Future<void> scheduleTaskReminder(Task task) async {
    debugPrint('Scheduling reminder for task: ${task.title}');

    if (task.dueDate == null) {
      debugPrint('No due date set for task ${task.title}. Skipping reminder.');
      return;
    }

    // Convert to local timezone
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime.from(task.dueDate!, tz.local);
    debugPrint('Current time: $now');
    debugPrint('Calculated scheduled date: $scheduledDate');

    // Ensure the scheduled date is in the future
    if (scheduledDate.isBefore(now)) {
      debugPrint('Task due date is in the past. Skipping reminder.');
      return;
    }

    // Don't schedule if the date is in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('Task due date is in the past. Skipping reminder.');
      return;
    }

    final androidDetails = const AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('complete', 'Complete'),
        AndroidNotificationAction('snooze', 'Snooze'),
      ],
    );

    final iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      threadIdentifier: task.id, // Group notifications by task
      categoryIdentifier: 'task_reminder',
      subtitle: 'Due: ${task.dueDate?.toLocal()}',
      sound: 'default',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    try {
      final hasExactAlarmPermission = await requestExactAlarmPermission();
      final scheduleMode = hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        task.id.hashCode,
        'Task Reminder: ${task.title}',
        task.description.isNotEmpty
            ? task.description
            : 'Your task "${task.title}" is due',
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: scheduleMode,
        payload: task.id,
      );

      debugPrint('Notification scheduled with mode: $scheduleMode');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      // Try scheduling with inexact timing as fallback
      if (e.toString().contains('exact_alarms_not_permitted')) {
        debugPrint('Retrying with inexact timing...');
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          task.id.hashCode,
          'Task Reminder: ${task.title}',
          task.description.isNotEmpty
              ? task.description
              : 'Your task "${task.title}" is due',
          scheduledDate,
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
        );
        debugPrint('Notification scheduled with inexact timing');
      } else {
        rethrow;
      }
    }

    debugPrint('Scheduled notification for task ${task.id} at $scheduledDate');
  }

  Future<void> cancelTaskReminder(Task task) async {
    await _flutterLocalNotificationsPlugin.cancel(task.id.hashCode);
    debugPrint('Cancelled notification for task ${task.id}');
  }

  Future<void> cancelAllReminders() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      debugPrint('Showing immediate notification - Title: $title, Body: $body');

      const androidDetails = AndroidNotificationDetails(
        'immediate_notifications',
        'Immediate Notifications',
        channelDescription: 'Notifications that should be shown immediately',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableLights: true,
        enableVibration: true,
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        sound: 'default',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.hashCode;
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('Immediate notification sent successfully with id: $id');

      // Verify the notification was scheduled
      final pending = await getPendingNotifications();
      debugPrint('Current pending notifications: ${pending.length}');
    } catch (e, stack) {
      debugPrint('Error showing notification: $e');
      debugPrint('Stack trace: $stack');
    }
  }
}
