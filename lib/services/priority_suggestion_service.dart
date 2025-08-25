import 'package:todoapp/models/task.dart';

class PrioritySuggestionService {
  /// Suggests a task priority based on various factors
  static TaskPriority suggestPriority({
    required DateTime? dueDate,
    required TaskCategory category,
    required String title,
    required String description,
  }) {
    int priorityScore = 0;

    // Due date analysis
    if (dueDate != null) {
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

      if (daysUntilDue <= 1) {
        priorityScore += 5; // Very urgent
      } else if (daysUntilDue <= 3) {
        priorityScore += 4; // Soon
      } else if (daysUntilDue <= 7) {
        priorityScore += 3; // This week
      } else if (daysUntilDue <= 14) {
        priorityScore += 2; // Next week
      } else {
        priorityScore += 1; // Far future
      }
    }

    // Category analysis
    priorityScore += _getCategoryPriorityScore(category);

    // Keyword analysis in title and description
    priorityScore += _analyzeKeywords('$title $description');

    // Convert score to priority
    return _convertScoreToPriority(priorityScore);
  }

  /// Assigns priority scores based on task category
  static int _getCategoryPriorityScore(TaskCategory category) {
    switch (category) {
      case TaskCategory.study:
        return 4; // High priority for study tasks
      case TaskCategory.work:
        return 3; // Important for work tasks
      case TaskCategory.health:
        return 3; // Health is important
      case TaskCategory.family:
        return 3; // Family commitments are important
      case TaskCategory.personal:
        return 2; // Medium priority
      case TaskCategory.creative:
        return 2;
      case TaskCategory.shopping:
        return 1;
      case TaskCategory.travel:
        return 1;
    }
  }

  /// Analyzes text for priority-indicating keywords
  static int _analyzeKeywords(String text) {
    text = text.toLowerCase();
    int score = 0;

    // Urgent keywords
    final urgentKeywords = [
      'urgent',
      'asap',
      'emergency',
      'deadline',
      'due',
      'exam',
      'test',
      'final',
      'midterm',
      'important',
      'critical',
    ];

    // High priority keywords
    final highPriorityKeywords = [
      'assessment',
      'assignment',
      'project',
      'presentation',
      'report',
      'submission',
    ];

    // Medium priority keywords
    final mediumPriorityKeywords = [
      'review',
      'prepare',
      'study',
      'read',
      'homework',
      'practice',
    ];

    // Count keyword occurrences
    for (final keyword in urgentKeywords) {
      if (text.contains(keyword)) score += 2;
    }

    for (final keyword in highPriorityKeywords) {
      if (text.contains(keyword)) score += 1;
    }

    for (final keyword in mediumPriorityKeywords) {
      if (text.contains(keyword)) score += 1;
    }

    return score;
  }

  /// Converts numeric score to TaskPriority
  static TaskPriority _convertScoreToPriority(int score) {
    if (score >= 8) {
      return TaskPriority.urgent;
    } else if (score >= 6) {
      return TaskPriority.high;
    } else if (score >= 4) {
      return TaskPriority.medium;
    } else {
      return TaskPriority.low;
    }
  }
}
