import 'package:flutter/material.dart';
import '../models/task.dart';

class IconUtils {
  static IconData getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.arrow_downward_rounded;
      case TaskPriority.medium:
        return Icons.remove_rounded;
      case TaskPriority.high:
        return Icons.arrow_upward_rounded;
      case TaskPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }

  static IconData getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return Icons.work_rounded;
      case TaskCategory.personal:
        return Icons.person_rounded;
      case TaskCategory.study:
        return Icons.school_rounded;
      case TaskCategory.health:
        return Icons.favorite_rounded;
      case TaskCategory.creative:
        return Icons.brush_rounded;
      case TaskCategory.travel:
        return Icons.flight_rounded;
      case TaskCategory.shopping:
        return Icons.shopping_cart_rounded;
      case TaskCategory.family:
        return Icons.family_restroom_rounded;
    }
  }
}
