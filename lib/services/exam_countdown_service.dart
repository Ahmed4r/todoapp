import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam.dart';
import '../models/task.dart';

class ExamCountdownService extends ChangeNotifier {
  static const String _examsKey = 'exams';
  static const String _studySessionsKey = 'study_sessions';
  static const String _activeExamKey = 'active_exam';

  List<Exam> _exams = [];
  List<StudySession> _studySessions = [];
  String? _activeExamId;
  Timer? _countdownTimer;

  // Getters
  List<Exam> get exams => List.unmodifiable(_exams);
  List<StudySession> get studySessions => List.unmodifiable(_studySessions);
  String? get activeExamId => _activeExamId;

  Exam? get activeExam => _activeExamId != null
      ? _exams.where((exam) => exam.id == _activeExamId).firstOrNull
      : null;

  List<Exam> get upcomingExams {
    final upcoming =
        _exams.where((exam) => exam.isUpcoming && exam.isActive).toList()
          ..sort((a, b) => a.examDate.compareTo(b.examDate));
    print(
      'DEBUG: upcomingExams getter called, found ${upcoming.length} upcoming exams from total ${_exams.length}',
    );
    return upcoming;
  }

  List<Exam> get todayExams =>
      _exams.where((exam) => exam.isToday && exam.isActive).toList();

  List<Exam> get urgentExams => _exams
      .where((exam) => exam.urgency == ExamUrgency.urgent && exam.isActive)
      .toList();

  // Initialize service
  Future<void> initialize() async {
    print('DEBUG: ExamCountdownService.initialize() called');
    await _loadExams();
    print('DEBUG: Exams loaded: ${_exams.length}');
    await _loadStudySessions();
    print('DEBUG: Study sessions loaded');
    await _loadActiveExam();
    print('DEBUG: Active exam loaded: $_activeExamId');
    _startCountdownTimer();
    print('DEBUG: Countdown timer started');
  }

  // Exam Management
  Future<void> addExam(Exam exam) async {
    print('DEBUG: ExamCountdownService.addExam called with: ${exam.title}');
    _exams.add(exam);
    print('DEBUG: Exam added to list, total exams: ${_exams.length}');
    await _saveExams();
    print('DEBUG: Exams saved to storage');
    notifyListeners();
    print('DEBUG: Listeners notified');
  }

  Future<void> updateExam(Exam updatedExam) async {
    final index = _exams.indexWhere((exam) => exam.id == updatedExam.id);
    if (index != -1) {
      _exams[index] = updatedExam;
      await _saveExams();
      notifyListeners();
    }
  }

  Future<void> deleteExam(String examId) async {
    _exams.removeWhere((exam) => exam.id == examId);
    if (_activeExamId == examId) {
      _activeExamId = null;
      await _saveActiveExam();
    }
    await _saveExams();
    notifyListeners();
  }

  Future<void> setActiveExam(String? examId) async {
    _activeExamId = examId;
    await _saveActiveExam();
    notifyListeners();
  }

  // Study Session Management
  Future<void> addStudySession(StudySession session) async {
    _studySessions.add(session);

    // Update exam study hours
    final exam = _exams.where((e) => e.id == session.examId).firstOrNull;
    if (exam != null) {
      final updatedExam = exam.copyWith(
        studyHoursCompleted: (exam.studyHoursCompleted + session.durationHours)
            .round(),
        updatedAt: DateTime.now(),
      );
      await updateExam(updatedExam);
    }

    await _saveStudySessions();
    notifyListeners();
  }

  Future<void> completeStudySession(String sessionId, int actualMinutes) async {
    final index = _studySessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _studySessions[index];
      final completedSession = session.copyWith(
        isCompleted: true,
        actualDurationMinutes: actualMinutes,
        completedAt: DateTime.now(),
      );

      _studySessions[index] = completedSession;

      // Update exam study hours
      final exam = _exams.where((e) => e.id == session.examId).firstOrNull;
      if (exam != null) {
        final hoursToAdd = actualMinutes / 60.0;
        final updatedExam = exam.copyWith(
          studyHoursCompleted: (exam.studyHoursCompleted + hoursToAdd).round(),
          updatedAt: DateTime.now(),
        );
        await updateExam(updatedExam);
      }

      await _saveStudySessions();
      notifyListeners();
    }
  }

  // Study Plan Generation
  List<StudySession> generateStudyPlan(Exam exam) {
    final now = DateTime.now();
    final daysUntilExam = exam.daysUntilExam;

    if (daysUntilExam <= 0) return [];

    final sessions = <StudySession>[];
    final dailyHours = exam.dailyStudyHoursNeeded;

    for (int day = 0; day < daysUntilExam; day++) {
      final sessionDate = now.add(Duration(days: day));

      // Create morning and evening sessions if needed
      if (dailyHours >= 2) {
        // Morning session
        sessions.add(
          StudySession(
            id: '${exam.id}_${day}_morning',
            examId: exam.id,
            title: 'جلسة مراجعة صباحية - ${exam.subject}',
            scheduledDate: DateTime(
              sessionDate.year,
              sessionDate.month,
              sessionDate.day,
              9, // 9 AM
            ),
            plannedDurationMinutes: (dailyHours * 30).round(),
            topics: _selectTopicsForSession(exam.topics, day, true),
            sessionType: day < daysUntilExam / 2
                ? StudySessionType.learning
                : StudySessionType.revision,
          ),
        );

        // Evening session
        sessions.add(
          StudySession(
            id: '${exam.id}_${day}_evening',
            examId: exam.id,
            title: 'جلسة مراجعة مسائية - ${exam.subject}',
            scheduledDate: DateTime(
              sessionDate.year,
              sessionDate.month,
              sessionDate.day,
              19, // 7 PM
            ),
            plannedDurationMinutes: (dailyHours * 30).round(),
            topics: _selectTopicsForSession(exam.topics, day, false),
            sessionType: day >= daysUntilExam * 0.7
                ? StudySessionType.practice
                : StudySessionType.learning,
          ),
        );
      } else {
        // Single session
        sessions.add(
          StudySession(
            id: '${exam.id}_${day}_single',
            examId: exam.id,
            title: 'جلسة مراجعة - ${exam.subject}',
            scheduledDate: DateTime(
              sessionDate.year,
              sessionDate.month,
              sessionDate.day,
              14, // 2 PM
            ),
            plannedDurationMinutes: (dailyHours * 60).round(),
            topics: _selectTopicsForSession(exam.topics, day, true),
            sessionType: _getSessionTypeForDay(day, daysUntilExam),
          ),
        );
      }
    }

    return sessions;
  }

  List<String> _selectTopicsForSession(
    List<String> allTopics,
    int day,
    bool isMorning,
  ) {
    if (allTopics.isEmpty) return [];

    final topicsPerSession = (allTopics.length / 4).ceil();
    final startIndex = (day * 2 + (isMorning ? 0 : 1)) * topicsPerSession;
    final endIndex = (startIndex + topicsPerSession).clamp(0, allTopics.length);

    return allTopics.sublist(startIndex.clamp(0, allTopics.length), endIndex);
  }

  StudySessionType _getSessionTypeForDay(int day, int totalDays) {
    final progress = day / totalDays;

    if (progress < 0.3) return StudySessionType.learning;
    if (progress < 0.7) return StudySessionType.revision;
    return StudySessionType.practice;
  }

  // Analytics
  Map<String, dynamic> getExamAnalytics(String examId) {
    final exam = _exams.where((e) => e.id == examId).firstOrNull;
    if (exam == null) return {};

    final sessions = _studySessions.where((s) => s.examId == examId).toList();
    final completedSessions = sessions.where((s) => s.isCompleted).length;
    final totalStudyMinutes = sessions
        .where((s) => s.isCompleted)
        .map((s) => s.actualDurationMinutes ?? s.plannedDurationMinutes)
        .fold<int>(0, (sum, minutes) => sum + minutes);

    return {
      'exam': exam,
      'totalSessions': sessions.length,
      'completedSessions': completedSessions,
      'sessionProgress': sessions.isEmpty
          ? 0.0
          : completedSessions / sessions.length,
      'totalStudyHours': totalStudyMinutes / 60.0,
      'studyProgress': exam.studyProgress,
      'daysUntilExam': exam.daysUntilExam,
      'dailyHoursNeeded': exam.dailyStudyHoursNeeded,
      'urgency': exam.urgency,
    };
  }

  List<Map<String, dynamic>> getAllExamAnalytics() {
    return _exams.map((exam) => getExamAnalytics(exam.id)).toList();
  }

  // Countdown Timer
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners(); // Update countdown displays
    });
  }

  // Storage Methods
  Future<void> _loadExams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final examsJson = prefs.getStringList(_examsKey) ?? [];
      _exams = examsJson
          .map((json) => Exam.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error loading exams: $e');
      _exams = [];
    }
  }

  Future<void> _saveExams() async {
    try {
      print('DEBUG: _saveExams called, saving ${_exams.length} exams');
      final prefs = await SharedPreferences.getInstance();
      final examsJson = _exams
          .map((exam) => jsonEncode(exam.toJson()))
          .toList();
      print('DEBUG: Converted exams to JSON');
      await prefs.setStringList(_examsKey, examsJson);
      print('DEBUG: Exams saved to SharedPreferences successfully');
    } catch (e) {
      print('DEBUG: Error saving exams: $e');
      debugPrint('Error saving exams: $e');
    }
  }

  Future<void> _loadStudySessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getStringList(_studySessionsKey) ?? [];
      _studySessions = sessionsJson
          .map((json) => StudySession.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error loading study sessions: $e');
      _studySessions = [];
    }
  }

  Future<void> _saveStudySessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = _studySessions
          .map((session) => jsonEncode(session.toJson()))
          .toList();
      await prefs.setStringList(_studySessionsKey, sessionsJson);
    } catch (e) {
      debugPrint('Error saving study sessions: $e');
    }
  }

  Future<void> _loadActiveExam() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activeExamId = prefs.getString(_activeExamKey);
    } catch (e) {
      debugPrint('Error loading active exam: $e');
    }
  }

  Future<void> _saveActiveExam() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeExamId != null) {
        await prefs.setString(_activeExamKey, _activeExamId!);
      } else {
        await prefs.remove(_activeExamKey);
      }
    } catch (e) {
      debugPrint('Error saving active exam: $e');
    }
  }

  // Quick Actions
  Future<List<Task>> generateStudyTasks(Exam exam) async {
    final tasks = <Task>[];
    final now = DateTime.now();

    for (int i = 0; i < exam.topics.length; i++) {
      final topic = exam.topics[i];
      final dueDate = now.add(Duration(days: i + 1));

      tasks.add(
        Task(
          id: '${exam.id}_task_$i',
          title: 'مراجعة: $topic',
          description:
              'مراجعة شاملة لموضوع $topic استعداداً لامتحان ${exam.subject}',
          category: TaskCategory.study,
          priority: exam.urgency == ExamUrgency.urgent
              ? TaskPriority.urgent
              : TaskPriority.high,
          dueDate: dueDate,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return tasks;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

// Study Session Model
class StudySession {
  final String id;
  final String examId;
  final String title;
  final DateTime scheduledDate;
  final int plannedDurationMinutes;
  final int? actualDurationMinutes;
  final List<String> topics;
  final StudySessionType sessionType;
  final bool isCompleted;
  final DateTime? completedAt;
  final String notes;

  const StudySession({
    required this.id,
    required this.examId,
    required this.title,
    required this.scheduledDate,
    required this.plannedDurationMinutes,
    this.actualDurationMinutes,
    this.topics = const [],
    this.sessionType = StudySessionType.learning,
    this.isCompleted = false,
    this.completedAt,
    this.notes = '',
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      examId: json['examId'] as String,
      title: json['title'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      plannedDurationMinutes: json['plannedDurationMinutes'] as int,
      actualDurationMinutes: json['actualDurationMinutes'] as int?,
      topics: List<String>.from(json['topics'] as List? ?? []),
      sessionType: StudySessionType.values[json['sessionType'] as int? ?? 0],
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examId': examId,
      'title': title,
      'scheduledDate': scheduledDate.toIso8601String(),
      'plannedDurationMinutes': plannedDurationMinutes,
      'actualDurationMinutes': actualDurationMinutes,
      'topics': topics,
      'sessionType': sessionType.index,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  StudySession copyWith({
    String? id,
    String? examId,
    String? title,
    DateTime? scheduledDate,
    int? plannedDurationMinutes,
    int? actualDurationMinutes,
    List<String>? topics,
    StudySessionType? sessionType,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
  }) {
    return StudySession(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      topics: topics ?? this.topics,
      sessionType: sessionType ?? this.sessionType,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  double get durationHours => plannedDurationMinutes / 60.0;
  bool get isToday => scheduledDate.day == DateTime.now().day;
  bool get isUpcoming => scheduledDate.isAfter(DateTime.now());
}

enum StudySessionType {
  learning, // تعلم جديد
  revision, // مراجعة
  practice, // تطبيق وممارسة
  testing, // اختبار ذاتي
}

extension StudySessionTypeExtension on StudySessionType {
  String get arabicName {
    switch (this) {
      case StudySessionType.learning:
        return 'تعلم جديد';
      case StudySessionType.revision:
        return 'مراجعة';
      case StudySessionType.practice:
        return 'تطبيق وممارسة';
      case StudySessionType.testing:
        return 'اختبار ذاتي';
    }
  }

  IconData get icon {
    switch (this) {
      case StudySessionType.learning:
        return Icons.school;
      case StudySessionType.revision:
        return Icons.refresh;
      case StudySessionType.practice:
        return Icons.fitness_center;
      case StudySessionType.testing:
        return Icons.quiz;
    }
  }

  Color get color {
    switch (this) {
      case StudySessionType.learning:
        return const Color(0xFF3B82F6);
      case StudySessionType.revision:
        return const Color(0xFF10B981);
      case StudySessionType.practice:
        return const Color(0xFFF59E0B);
      case StudySessionType.testing:
        return const Color(0xFFEF4444);
    }
  }
}
