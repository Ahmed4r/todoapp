import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/task.dart';
import '../services/study_note_service.dart';
import '../widgets/audio_wave.dart';

class RecordingPage extends StatefulWidget {
  final Task task;
  final String? sessionId;
  final StudyNoteService noteService;

  const RecordingPage({
    super.key,
    required this.task,
    this.sessionId,
    required this.noteService,
  });

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      await widget.noteService.startRecording(widget.task.id, widget.sessionId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _togglePause() async {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      await widget.noteService.pauseRecording();
    } else {
      await widget.noteService.resumeRecording();
    }
  }

  Future<bool> _confirmCloseRecording() async {
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Recording?'),
        content: const Text(
          'Are you sure you want to cancel the recording? The recording will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return shouldClose ?? false;
  }

  Future<bool> _confirmStopRecording() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Recording?'),
        content: const Text('Do you want to save this recording?'),
        actions: [
          TextButton(
            onPressed: () {
              widget.noteService.cancelRecording();
              Navigator.pop(context, false);
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return shouldSave ?? false;
  }

  Future<void> _stopAndSave() async {
    final shouldSave = await _confirmStopRecording();
    if (!mounted) return;

    try {
      if (shouldSave) {
        await widget.noteService.stopRecording(
          taskId: widget.task.id,
          sessionId: widget.sessionId,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save recording: $e')));
      }
    }
  }

  @override
  void dispose() {
    if (widget.noteService.isRecording) {
      widget.noteService.cancelRecording();
    }
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldClose = await _confirmCloseRecording();
        if (shouldClose) {
          widget.noteService.cancelRecording();
        }
        return shouldClose;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Recording'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldClose = await _confirmCloseRecording();
              if (shouldClose && mounted) {
                widget.noteService.cancelRecording();
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(onPressed: _stopAndSave, child: const Text('Save')),
          ],
        ),
        body: AnimatedBuilder(
          animation: widget.noteService,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDuration(widget.noteService.recordingDuration),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 32.h),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16.w),
                  ),
                  child: AudioWave(
                    isRecording: widget.noteService.isRecording && !_isPaused,
                  ),
                ),
                SizedBox(height: 48.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: 'pause_button',
                      onPressed: _togglePause,
                      child: Icon(_isPaused ? Icons.mic : Icons.pause),
                    ),
                    SizedBox(width: 24.w),
                    FloatingActionButton(
                      heroTag: 'stop_button',
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      onPressed: _stopAndSave,
                      child: const Icon(Icons.stop),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
