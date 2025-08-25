import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as audio_recorder;
import '../models/study_note.dart';
import 'audio_service.dart';

class StudyNoteService extends ChangeNotifier {
  final List<StudyNote> _notes = [];
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  final _audioRecorder = audio_recorder.AudioRecorder();
  final AudioService _audioService = AudioService();

  StudyNoteService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    if (_isInitialized) return;
    await _loadNotes();
    _isInitialized = true;
  }

  List<StudyNote> get notes => _notes;
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  int get recordingDuration => _recordingDuration;

  Future<void> pauseRecording() async {
    if (!_isRecording || _isPaused) return;

    try {
      _recordingTimer?.cancel();
      await _audioRecorder.pause();
      _isPaused = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing recording: $e');
      rethrow;
    }
  }

  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) return;

    try {
      await _audioRecorder.resume();
      _isPaused = false;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming recording: $e');
      rethrow;
    }
  }

  // Get notes for a specific task
  List<StudyNote> getNotesForTask(String taskId) {
    return _notes.where((note) => note.taskId == taskId).toList();
  }

  // Get notes for a specific pomodoro session
  List<StudyNote> getNotesForSession(String sessionId) {
    return _notes.where((note) => note.sessionId == sessionId).toList();
  }

  // Add a text note
  Future<void> addTextNote({
    required String content,
    required String taskId,
    String? sessionId,
  }) async {
    final note = StudyNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
      taskId: taskId,
      sessionId: sessionId,
      type: NoteType.text,
    );

    _notes.add(note);
    notifyListeners();
    await _saveNotes();
  }

  // Start recording a voice note
  Future<void> startRecording(String taskId, [String? sessionId]) async {
    try {
      // Stop any ongoing recording
      if (_isRecording) {
        await stopRecording(taskId: taskId, sessionId: sessionId);
      }

      // Check permissions
      if (!await _audioRecorder.hasPermission()) {
        debugPrint('Requesting microphone permission...');
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          throw Exception('Microphone permission denied');
        }
      }

      // Initialize recording path
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = '${directory.path}/$fileName';

      debugPrint('Starting recording at: $_currentRecordingPath');

      // Configure and start recording
      await _audioRecorder.start(
        const audio_recorder.RecordConfig(
          encoder: audio_recorder.AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 2,
        ),
        path: _currentRecordingPath!,
      );

      // Update state
      _isRecording = true;
      _recordingDuration = 0;
      notifyListeners();

      // Start duration timer
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
        notifyListeners();
      });

      debugPrint('Recording started successfully');
    } catch (e, stackTrace) {
      debugPrint('Error starting recording: $e');
      debugPrint('Stack trace: $stackTrace');
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingDuration = 0;
      notifyListeners();
      rethrow;
    }
  }

  // Stop recording and save the voice note
  Future<void> stopRecording({
    required String taskId,
    String? sessionId,
  }) async {
    if (!_isRecording) {
      debugPrint('No active recording to stop');
      return;
    }

    try {
      debugPrint('Stopping recording...');
      _recordingTimer?.cancel();
      final path = _currentRecordingPath;

      if (path != null) {
        debugPrint('Saving recording from path: $path');
        final recordedPath = await _audioRecorder.stop();
        debugPrint('Recording stopped, saved at: $recordedPath');

        if (recordedPath != null) {
          // Verify the file exists and has content
          final file = File(recordedPath);
          if (await file.exists()) {
            final fileSize = await file.length();
            debugPrint('Recorded file size: $fileSize bytes');

            if (fileSize > 0) {
              final note = StudyNote(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content: 'Voice Note (${_formatDuration(_recordingDuration)})',
                createdAt: DateTime.now(),
                taskId: taskId,
                sessionId: sessionId,
                type: NoteType.voice,
                voicePath: recordedPath,
              );

              _notes.add(note);
              await _saveNotes();
              debugPrint('Voice note saved successfully');
            } else {
              debugPrint('Warning: Recorded file is empty');
            }
          } else {
            debugPrint(
              'Warning: Recorded file not found at path: $recordedPath',
            );
          }
        } else {
          debugPrint('Warning: No path returned from stop recording');
        }
      }

      _isRecording = false;
      _recordingDuration = 0;
      _currentRecordingPath = null;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error stopping recording: $e');
      debugPrint('Stack trace: $stackTrace');

      // Reset state even if there's an error
      _isRecording = false;
      _recordingDuration = 0;
      _currentRecordingPath = null;
      notifyListeners();

      rethrow;
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      _recordingTimer?.cancel();

      if (_isRecording) {
        await _audioRecorder.stop();
      }

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _isRecording = false;
      _recordingDuration = 0;
      _currentRecordingPath = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error canceling recording: $e');
      rethrow;
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    final noteIndex = _notes.indexWhere((note) => note.id == noteId);
    if (noteIndex != -1) {
      final note = _notes[noteIndex];
      if (note.type == NoteType.voice && note.voicePath != null) {
        final file = File(note.voicePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _notes.removeAt(noteIndex);
      notifyListeners();
      await _saveNotes();
    }
  }

  // Helper method to format recording duration
  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Load notes from persistent storage
  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('study_notes') ?? [];
      _notes.clear();
      _notes.addAll(
        notesJson.map((json) => StudyNote.fromJson(jsonDecode(json))).toList(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }

  // Save notes to persistent storage
  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = _notes
          .map((note) => jsonEncode(note.toJson()))
          .toList();
      await prefs.setStringList('study_notes', notesJson);
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  // Play voice note
  Future<void> playVoiceNote(StudyNote note) async {
    if (note.type != NoteType.voice || note.voicePath == null) {
      debugPrint('Invalid voice note or missing path');
      return;
    }

    try {
      final file = File(note.voicePath!);
      if (!await file.exists()) {
        debugPrint('Voice file not found: ${note.voicePath}');
        return;
      }

      await _audioService.playAudio(note.voicePath!);
    } catch (e) {
      debugPrint('Error playing voice note: $e');
    }
  }

  // Stop voice note playback
  Future<void> stopPlayback() async {
    await _audioService.stopAudio();
  }

  bool isPlayingNote(StudyNote note) {
    return _audioService.isPlaying &&
        _audioService.currentAudioPath == note.voicePath;
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    if (_isRecording) {
      cancelRecording();
    }
    _audioService.dispose();
    super.dispose();
  }
}
