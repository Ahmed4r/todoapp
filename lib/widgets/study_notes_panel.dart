import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/study_note.dart';
import '../models/task.dart';
import '../services/study_note_service.dart';
import '../screens/recording_page.dart';

class StudyNotesPanel extends StatefulWidget {
  final Task task;
  final String? sessionId;
  final StudyNoteService noteService;

  const StudyNotesPanel({
    super.key,
    required this.task,
    this.sessionId,
    required this.noteService,
  });

  @override
  State<StudyNotesPanel> createState() => _StudyNotesPanelState();
}

class _StudyNotesPanelState extends State<StudyNotesPanel> {
  final TextEditingController _noteController = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          ListTile(
            title: Text(
              'Study Notes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: 'Add a note...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.w),
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (_noteController.text.isNotEmpty) {
                            widget.noteService.addTextNote(
                              content: _noteController.text,
                              taskId: widget.task.id,
                              sessionId: widget.sessionId,
                            );
                            _noteController.clear();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RecordingPage(
                                task: widget.task,
                                sessionId: widget.sessionId,
                                noteService: widget.noteService,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Notes list
            AnimatedBuilder(
              animation: widget.noteService,
              builder: (context, _) {
                final notes = widget.sessionId != null
                    ? widget.noteService.getNotesForSession(widget.sessionId!)
                    : widget.noteService.getNotesForTask(widget.task.id);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteItem(note);
                  },
                );
              },
            ),
            SizedBox(height: 16.h),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteItem(StudyNote note) {
    final isPlaying = widget.noteService.isPlayingNote(note);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (note.type == NoteType.voice)
            MaterialButton(
              onPressed: () {
                if (isPlaying) {
                  widget.noteService.stopPlayback();
                } else {
                  widget.noteService.playVoiceNote(note);
                }
              },
              color: isPlaying
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              elevation: 0,
              shape: const CircleBorder(),
              padding: EdgeInsets.all(12.w),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isPlaying
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
                size: 24.w,
              ),
            )
          else
            Icon(
              Icons.note,
              size: 24.w,
              color: Theme.of(context).colorScheme.primary,
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4.h),
                Text(
                  _formatDateTime(note.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => widget.noteService.deleteNote(note.id),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
