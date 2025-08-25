import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/study_note_service.dart';
import 'study_notes_panel.dart';

class NotesBottomSheet extends StatelessWidget {
  final Task task;

  const NotesBottomSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<StudyNoteService>(context, listen: false);
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2.h),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          overflow: TextOverflow.clip,
                          'Notes for "${task.title}"',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  StudyNotesPanel(task: task, noteService: noteService),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
