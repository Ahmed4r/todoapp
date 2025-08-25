import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Maximum positive 32-bit signed integer (used by platform notification ids)
  static const int _kMaxInt32 = 0x7fffffff;

  // Convert a string id into a stable, 32-bit safe integer id for notifications.
  // If the string is a numeric value that fits into 32-bit range we use it
  // (otherwise we map it into the 32-bit range). For non-numeric ids we use
  // the string hashCode masked into the positive 32-bit range.
  int _safeId(String id) {
    try {
      final parsed = int.parse(id);
      // Map into range [0, _kMaxInt32]
      final mod = parsed % _kMaxInt32;
      return mod >= 0 ? mod : (mod + _kMaxInt32);
    } catch (_) {
      return id.hashCode & _kMaxInt32;
    }
  }

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize timezone data
    tzdata.initializeTimeZones();

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // iOS / macOS: request permissions via Darwin implementation
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Android: runtime POST_NOTIFICATIONS permission (Android 13+)
    // We declare the permission in AndroidManifest.xml below; to prompt
    // the user at runtime use a runtime-permission plugin such as
    // `permission_handler` or platform channels. This repo currently
    // declares the permission in the manifest so notifications can work
    // on Android when granted.
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (task.dueDate == null) return;

    final int taskId = _safeId(task.id);
    final String title = 'Task Reminder';
    final String body = 'Your task "${task.title}" is due soon!';

    // Schedule notification 1 hour before due date
    final scheduledDate = task.dueDate!.subtract(const Duration(hours: 1));

    // Only schedule if the time is in the future
    if (scheduledDate.isAfter(DateTime.now())) {
      try {
        await _notifications.zonedSchedule(
          taskId,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Task Reminders',
              channelDescription: 'Notifications for task reminders',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: Color(0xFF007AFF),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: task.id,
        );
      } catch (e) {
        // Fallback to inexact scheduling if exact alarms are not permitted
        debugPrint('Exact alarm not permitted, using inexact scheduling: $e');
        await _notifications.zonedSchedule(
          taskId,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Task Reminders',
              channelDescription: 'Notifications for task reminders',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: Color(0xFF007AFF),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
        );
      }
    }

    // Also schedule a notification for the exact due time
    try {
      await _notifications.zonedSchedule(
        taskId +
            1000, // Different ID for due time notification (offset within 32-bit range)
        'Task Due Now',
        'Your task "${task.title}" is due now!',
        tz.TZDateTime.from(task.dueDate!, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_due',
            'Task Due',
            channelDescription: 'Notifications for tasks due now',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFFF3B30),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id,
      );
    } catch (e) {
      // Fallback to inexact scheduling if exact alarms are not permitted
      debugPrint(
          'Exact alarm not permitted for due time, using inexact scheduling: $e');
      await _notifications.zonedSchedule(
        taskId + 1000,
        'Task Due Now',
        'Your task "${task.title}" is due now!',
        tz.TZDateTime.from(task.dueDate!, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_due',
            'Task Due',
            channelDescription: 'Notifications for tasks due now',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFFF3B30),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: task.id,
      );
    }
  }

  Future<void> cancelTaskReminder(Task task) async {
    final int taskId = _safeId(task.id);
    await _notifications.cancel(taskId);
    await _notifications.cancel(taskId + 1000); // Cancel due time notification
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate',
          'Immediate Notifications',
          channelDescription: 'Immediate notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
