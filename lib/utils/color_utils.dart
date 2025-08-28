import 'package:flutter/material.dart';
import '../models/task.dart';

class ColorUtils {
  static Color getCategoryColor(
    TaskCategory category, [
    BuildContext? context,
  ]) {
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;
    switch (category) {
      case TaskCategory.work:
        return isDark ? const Color(0xFF5AC8FA) : const Color(0xFF007AFF);
      case TaskCategory.personal:
        return isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
      case TaskCategory.study:
        return isDark ? const Color(0xFFFFCC02) : const Color(0xFFFF9500);
      case TaskCategory.health:
        return isDark ? const Color(0xFFFF6961) : const Color(0xFFFF3B30);
      case TaskCategory.creative:
        return isDark ? const Color(0xFFBF5AF2) : const Color(0xFFAF52DE);
      case TaskCategory.travel:
        return isDark ? const Color(0xFF64D2FF) : const Color(0xFF5AC8FA);
      case TaskCategory.shopping:
        return isDark ? const Color(0xFFFFCC02) : const Color(0xFFFF9500);
      case TaskCategory.family:
        return isDark ? const Color(0xFFFF375F) : const Color(0xFFFF2D92);
    }
  }

  static Color getPriorityColor(
    TaskPriority priority, [
    BuildContext? context,
  ]) {
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;
    switch (priority) {
      case TaskPriority.low:
        return isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
      case TaskPriority.medium:
        return isDark ? const Color(0xFFFFCC02) : const Color(0xFFFF9500);
      case TaskPriority.high:
        return isDark ? const Color(0xFFFF6961) : const Color(0xFFFF3B30);
      case TaskPriority.urgent:
        return isDark ? const Color(0xFFBF5AF2) : const Color(0xFFAF52DE);
    }
  }

  static Color getDueDateColor(Task task, [BuildContext? context]) {
    if (task.dueDate == null)
      return context != null
          ? Theme.of(context).colorScheme.outline
          : Colors.grey;
    if (task.isCompleted) {
      final isDark = context != null
          ? Theme.of(context).brightness == Brightness.dark
          : false;
      return isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
    }

    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;

    if (dueDate.isBefore(now))
      return isDark
          ? const Color(0xFFFF6961)
          : const Color(0xFFFF3B30); // Overdue
    if (dueDate.day == now.day &&
        dueDate.month == now.month &&
        dueDate.year == now.year) {
      return isDark
          ? const Color(0xFFFFCC02)
          : const Color(0xFFFF9500); // Due today
    }
    if (dueDate.difference(now).inDays <= 1) {
      return isDark
          ? const Color(0xFFFFCC02)
          : const Color(0xFFFF9500); // Due tomorrow
    }
    return context != null
        ? Theme.of(context).colorScheme.outline
        : Colors.grey; // Future date
  }

  static String getDueDateText(Task task) {
    if (task.dueDate == null) return '';

    final now = DateTime.now();
    final dueDate = task.dueDate!;

    if (dueDate.isBefore(now)) return 'Overdue';
    if (dueDate.day == now.day &&
        dueDate.month == now.month &&
        dueDate.year == now.year) {
      return 'Due today';
    }
    if (dueDate.difference(now).inDays <= 1) {
      return 'Due tomorrow';
    }
    return 'Due ${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }

  static String getDueDateTimeText(Task task) {
    if (task.dueDate == null) return '';

    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final hasTime = dueDate.hour != 0 || dueDate.minute != 0;

    if (dueDate.isBefore(now)) {
      return hasTime ? 'Overdue at ${_formatTime(dueDate)}' : 'Overdue';
    }

    if (dueDate.day == now.day &&
        dueDate.month == now.month &&
        dueDate.year == now.year) {
      return hasTime ? 'Due today at ${_formatTime(dueDate)}' : 'Due today';
    }

    if (dueDate.difference(now).inDays <= 1) {
      return hasTime
          ? 'Due tomorrow at ${_formatTime(dueDate)}'
          : 'Due tomorrow';
    }

    if (hasTime) {
      return 'Due ${dueDate.day}/${dueDate.month}/${dueDate.year} at ${_formatTime(dueDate)}';
    } else {
      return 'Due ${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
