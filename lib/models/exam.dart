import 'package:flutter/material.dart';

class Exam {
  final String id;
  final String title;
  final String subject;
  final DateTime examDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ExamType type;
  final ExamDifficulty difficulty;
  final String description;
  final List<String> topics;
  final int studyHoursNeeded;
  final int studyHoursCompleted;
  final Color color;
  final bool isActive;

  const Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.examDate,
    required this.createdAt,
    required this.updatedAt,
    this.type = ExamType.written,
    this.difficulty = ExamDifficulty.medium,
    this.description = '',
    this.topics = const [],
    this.studyHoursNeeded = 20,
    this.studyHoursCompleted = 0,
    this.color = const Color(0xFF6366F1),
    this.isActive = true,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      examDate: DateTime.parse(json['examDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      type: ExamType.values[json['type'] as int? ?? 0],
      difficulty: ExamDifficulty.values[json['difficulty'] as int? ?? 1],
      description: json['description'] as String? ?? '',
      topics: List<String>.from(json['topics'] as List? ?? []),
      studyHoursNeeded: json['studyHoursNeeded'] as int? ?? 20,
      studyHoursCompleted: json['studyHoursCompleted'] as int? ?? 0,
      color: Color(json['color'] as int? ?? 0xFF6366F1),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'examDate': examDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.index,
      'difficulty': difficulty.index,
      'description': description,
      'topics': topics,
      'studyHoursNeeded': studyHoursNeeded,
      'studyHoursCompleted': studyHoursCompleted,
      'color': color.value,
      'isActive': isActive,
    };
  }

  Exam copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? examDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    ExamType? type,
    ExamDifficulty? difficulty,
    String? description,
    List<String>? topics,
    int? studyHoursNeeded,
    int? studyHoursCompleted,
    Color? color,
    bool? isActive,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      examDate: examDate ?? this.examDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      topics: topics ?? this.topics,
      studyHoursNeeded: studyHoursNeeded ?? this.studyHoursNeeded,
      studyHoursCompleted: studyHoursCompleted ?? this.studyHoursCompleted,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper getters
  Duration get timeUntilExam => examDate.difference(DateTime.now());
  int get daysUntilExam => timeUntilExam.inDays;
  int get hoursUntilExam => timeUntilExam.inHours;
  int get minutesUntilExam => timeUntilExam.inMinutes;

  bool get isUpcoming => timeUntilExam.inMinutes > 0;
  bool get isPassed => timeUntilExam.inMinutes <= 0;
  bool get isToday => daysUntilExam == 0 && isUpcoming;
  bool get isTomorrow => daysUntilExam == 1;
  bool get isThisWeek => daysUntilExam <= 7 && daysUntilExam > 0;

  double get studyProgress => studyHoursNeeded > 0
      ? (studyHoursCompleted / studyHoursNeeded).clamp(0.0, 1.0)
      : 0.0;

  int get remainingStudyHours =>
      (studyHoursNeeded - studyHoursCompleted).clamp(0, studyHoursNeeded);

  double get dailyStudyHoursNeeded {
    if (daysUntilExam <= 0 || remainingStudyHours <= 0) return 0.0;
    return remainingStudyHours / daysUntilExam;
  }

  ExamUrgency get urgency {
    if (isPassed) return ExamUrgency.passed;
    if (isToday) return ExamUrgency.today;
    if (isTomorrow) return ExamUrgency.tomorrow;
    if (daysUntilExam <= 3) return ExamUrgency.urgent;
    if (isThisWeek) return ExamUrgency.soon;
    return ExamUrgency.distant;
  }

  String get urgencyMessage {
    switch (urgency) {
      case ExamUrgency.passed:
        return 'انتهى الامتحان';
      case ExamUrgency.today:
        return 'اليوم!';
      case ExamUrgency.tomorrow:
        return 'غداً';
      case ExamUrgency.urgent:
        return 'خلال ${daysUntilExam} أيام';
      case ExamUrgency.soon:
        return 'خلال أسبوع';
      case ExamUrgency.distant:
        return 'خلال ${daysUntilExam} يوم';
    }
  }

  String get formattedCountdown {
    if (isPassed) return 'انتهى';
    if (daysUntilExam > 0) {
      return '${daysUntilExam}د ${timeUntilExam.inHours % 24}س';
    } else {
      return '${hoursUntilExam}س ${minutesUntilExam % 60}د';
    }
  }
}

enum ExamType {
  written, // امتحان كتابي
  oral, // امتحان شفهي
  practical, // امتحان عملي
  presentation, // عرض تقديمي
  project, // مشروع
  quiz, // اختبار قصير
}

enum ExamDifficulty {
  easy, // سهل
  medium, // متوسط
  hard, // صعب
  expert, // خبير
}

enum ExamUrgency {
  passed, // انتهى
  today, // اليوم
  tomorrow, // غداً
  urgent, // عاجل (1-3 أيام)
  soon, // قريب (4-7 أيام)
  distant, // بعيد (أكثر من أسبوع)
}

extension ExamTypeExtension on ExamType {
  String get arabicName {
    switch (this) {
      case ExamType.written:
        return 'امتحان كتابي';
      case ExamType.oral:
        return 'امتحان شفهي';
      case ExamType.practical:
        return 'امتحان عملي';
      case ExamType.presentation:
        return 'عرض تقديمي';
      case ExamType.project:
        return 'مشروع';
      case ExamType.quiz:
        return 'اختبار قصير';
    }
  }

  IconData get icon {
    switch (this) {
      case ExamType.written:
        return Icons.edit_note;
      case ExamType.oral:
        return Icons.record_voice_over;
      case ExamType.practical:
        return Icons.science;
      case ExamType.presentation:
        return Icons.slideshow;
      case ExamType.project:
        return Icons.assignment;
      case ExamType.quiz:
        return Icons.quiz;
    }
  }
}

extension ExamDifficultyExtension on ExamDifficulty {
  String get arabicName {
    switch (this) {
      case ExamDifficulty.easy:
        return 'سهل';
      case ExamDifficulty.medium:
        return 'متوسط';
      case ExamDifficulty.hard:
        return 'صعب';
      case ExamDifficulty.expert:
        return 'خبير';
    }
  }

  Color get color {
    switch (this) {
      case ExamDifficulty.easy:
        return const Color(0xFF10B981);
      case ExamDifficulty.medium:
        return const Color(0xFFF59E0B);
      case ExamDifficulty.hard:
        return const Color(0xFFEF4444);
      case ExamDifficulty.expert:
        return const Color(0xFF8B5CF6);
    }
  }
}

extension ExamUrgencyExtension on ExamUrgency {
  String get arabicName {
    switch (this) {
      case ExamUrgency.passed:
        return 'انتهى';
      case ExamUrgency.today:
        return 'اليوم';
      case ExamUrgency.tomorrow:
        return 'غداً';
      case ExamUrgency.urgent:
        return 'عاجل';
      case ExamUrgency.soon:
        return 'قريب';
      case ExamUrgency.distant:
        return 'بعيد';
    }
  }

  Color get color {
    switch (this) {
      case ExamUrgency.passed:
        return const Color(0xFF6B7280);
      case ExamUrgency.today:
        return const Color(0xFFDC2626);
      case ExamUrgency.tomorrow:
        return const Color(0xFFEA580C);
      case ExamUrgency.urgent:
        return const Color(0xFFF59E0B);
      case ExamUrgency.soon:
        return const Color(0xFF3B82F6);
      case ExamUrgency.distant:
        return const Color(0xFF10B981);
    }
  }
}
