import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

enum PomodoroState { ready, running, paused, break_time, completed }

class PomodoroSession {
  final String id;
  final Task task;
  final DateTime startTime;
  final int focusDuration;
  final int breakDuration;
  int completedPomodoros;
  int totalFocusTimeInSeconds;
  int totalBreakTimeInSeconds;
  int get totalSessionTimeInSeconds =>
      totalFocusTimeInSeconds + totalBreakTimeInSeconds;

  PomodoroSession({
    required this.id,
    required this.task,
    required this.startTime,
    this.focusDuration = 25 * 60, // 25 minutes in seconds
    this.breakDuration = 5 * 60, // 5 minutes in seconds
    this.completedPomodoros = 0,
    this.totalFocusTimeInSeconds = 0,
    this.totalBreakTimeInSeconds = 0,
  });
}

class PomodoroService extends ChangeNotifier {
  Timer? _timer;
  PomodoroState _state = PomodoroState.ready;
  PomodoroSession? _currentSession;
  int _remainingSeconds = 0;
  final List<PomodoroSession> _sessions = [];

  // Getters
  PomodoroState get state => _state;
  PomodoroSession? get currentSession => _currentSession;
  int get remainingSeconds => _remainingSeconds;
  List<PomodoroSession> get sessions => _sessions;

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (_currentSession == null) return 0;
    int totalSeconds = _state == PomodoroState.break_time
        ? _currentSession!.breakDuration
        : _currentSession!.focusDuration;
    return 1 - (_remainingSeconds / totalSeconds);
  }

  void startNewSession(Task task, {int? focusDuration, int? breakDuration}) {
    _checkDisposed();
    _currentSession = PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      task: task,
      startTime: DateTime.now(),
      focusDuration: focusDuration ?? (25 * 60), // 25 minutes in seconds
      breakDuration: breakDuration ?? (5 * 60), // 5 minute in seconds
    );
    _remainingSeconds = _currentSession!.focusDuration;
    _state = PomodoroState.ready;
    notifyListeners();
  }

  void start() {
    _checkDisposed();
    if (_currentSession == null) return;

    // Cancel any existing timer first
    _timer?.cancel();
    _timer = null;

    // Keep break_time state if we're in break time, otherwise set to running
    if (_state != PomodoroState.break_time) {
      _state = PomodoroState.running;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        // Track total time for statistics
        if (_state == PomodoroState.running) {
          _currentSession!.totalFocusTimeInSeconds++;
        } else if (_state == PomodoroState.break_time) {
          _currentSession!.totalBreakTimeInSeconds++;
        }
        notifyListeners();
      } else {
        if (_state == PomodoroState.running) {
          _currentSession!.completedPomodoros++;
          // Save completed pomodoro to daily count
          _saveDailyPomodoroCount();
          _state = PomodoroState.break_time;
          _remainingSeconds = _currentSession!.breakDuration;
          // Auto-start break timer
          timer.cancel();
          _timer = null;
          start();
        } else if (_state == PomodoroState.break_time) {
          _state = PomodoroState.ready;
          _remainingSeconds = _currentSession!.focusDuration;
        }
        timer.cancel();
        _timer = null;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pause() {
    _checkDisposed();
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      _state = PomodoroState.paused;
      notifyListeners();
    }
  }

  void resume() {
    if (_state == PomodoroState.paused) {
      start();
    }
  }

  void stop() {
    _checkDisposed();
    _timer?.cancel();
    _timer = null;
    if (_currentSession != null) {
      _sessions.add(_currentSession!);
    }
    _currentSession = null;
    _state = PomodoroState.ready;
    _remainingSeconds = 0;
    notifyListeners();
  }

  void skipBreak() {
    _checkDisposed();
    if (_state == PomodoroState.break_time) {
      _timer?.cancel();
      _timer = null;
      _state = PomodoroState.ready;
      _remainingSeconds = _currentSession!.focusDuration;
      notifyListeners();
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _disposed = true;
    super.dispose();
  }

  void _checkDisposed() {
    if (_disposed) {
      throw FlutterError(
        'A PomodoroService was used after being disposed.\n'
        'Once you have called dispose() on a PomodoroService, it can no longer be used.',
      );
    }
  }

  // Save completed pomodoro to daily count
  Future<void> _saveDailyPomodoroCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final currentCount = prefs.getInt('pomodoro_count_$today') ?? 0;
      final newCount = currentCount + 1;

      await prefs.setInt('pomodoro_count_$today', newCount);
      debugPrint('Pomodoro completed! Daily count: $newCount');
    } catch (e) {
      debugPrint('Error saving daily pomodoro count: $e');
    }
  }

  // Get today's pomodoro count
  Future<int> getTodayPomodoroCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      return prefs.getInt('pomodoro_count_$today') ?? 0;
    } catch (e) {
      debugPrint('Error getting daily pomodoro count: $e');
      return 0;
    }
  }
}
