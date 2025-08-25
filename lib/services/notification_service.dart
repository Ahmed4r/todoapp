import 'package:flutter/material.dart';
// The project currently has `flutter_local_notifications` and `timezone`
// commented out in `pubspec.yaml`. Provide a safe no-op implementation so
// the rest of the app can compile and run without those packages. If you
// re-enable the packages in `pubspec.yaml`, you can restore the full
// implementation that uses the plugin and timezone APIs.
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notifications are disabled in `pubspec.yaml` for CI/local runs.
  // The full implementation that uses `flutter_local_notifications` and
  // `timezone` is intentionally omitted while those packages are commented
  // out so the app can compile. Re-enable the packages and restore the
  // full implementation when ready.

  // No-op implementation below -------------------------------------------------

  Future<void> initialize() async {
    debugPrint(
      'NotificationService: initialize() called but notifications are disabled via pubspec.',
    );
    // No plugin initialization because flutter_local_notifications is disabled.
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (task.dueDate == null) return;
    debugPrint(
      'NotificationService: scheduleTaskReminder() skipped for task ${task.id} because notifications are disabled.',
    );
  }

  Future<void> cancelTaskReminder(Task task) async {
    debugPrint(
      'NotificationService: cancelTaskReminder() skipped for task ${task.id}.',
    );
  }

  Future<void> cancelAllReminders() async {
    debugPrint('NotificationService: cancelAllReminders() skipped.');
  }

  Future<List<dynamic>> getPendingNotifications() async {
    debugPrint(
      'NotificationService: getPendingNotifications() returning empty list.',
    );
    return <dynamic>[];
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint(
      'NotificationService: showImmediateNotification() called but disabled. title=$title body=$body payload=$payload',
    );
  }
}
