import 'package:flutter/material.dart';
import '../models/task.dart';

class ColorUtils {
  static Color getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return const Color(0xFF007AFF);
      case TaskCategory.personal:
        return const Color(0xFF34C759);
      case TaskCategory.study:
        return const Color(0xFFFF9500);
      case TaskCategory.health:
        return const Color(0xFFFF3B30);
      case TaskCategory.creative:
        return const Color(0xFFAF52DE);
      case TaskCategory.travel:
        return const Color(0xFF5AC8FA);
      case TaskCategory.shopping:
        return const Color(0xFFFF9500);
      case TaskCategory.family:
        return const Color(0xFFFF2D92);
    }
  }

  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(0xFF34C759);
      case TaskPriority.medium:
        return const Color(0xFFFF9500);
      case TaskPriority.high:
        return const Color(0xFFFF3B30);
      case TaskPriority.urgent:
        return const Color(0xFFAF52DE);
    }
  }

  static Color getDueDateColor(Task task) {
    if (task.dueDate == null) return Colors.grey;
    if (task.isCompleted) return const Color(0xFF34C759);

    final now = DateTime.now();
    final dueDate = task.dueDate!;

    if (dueDate.isBefore(now)) return const Color(0xFFFF3B30); // Overdue
    if (dueDate.day == now.day &&
        dueDate.month == now.month &&
        dueDate.year == now.year) {
      return const Color(0xFFFF9500); // Due today
    }
    if (dueDate.difference(now).inDays <= 1) {
      return const Color(0xFFFF9500); // Due tomorrow
    }
    return Colors.grey; // Future date
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
      return hasTime ? 'Due tomorrow at ${_formatTime(dueDate)}' : 'Due tomorrow';
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
