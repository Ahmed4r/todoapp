import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/task.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';
import '../services/priority_suggestion_service.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(
    String title,
    String description,
    DateTime? dueDate,
    TaskPriority priority,
    TaskCategory category,
  )
  onAddTask;

  const AddTaskDialog({super.key, required this.onAddTask});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  TaskPriority selectedPriority = TaskPriority.medium;
  TaskCategory selectedCategory = TaskCategory.personal;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    _taskController.clear();
    _descriptionController.clear();

    // Add listeners for auto-priority suggestion
    _taskController.addListener(_updateSuggestedPriority);
    _descriptionController.addListener(_updateSuggestedPriority);
  }

  @override
  void dispose() {
    _taskController.removeListener(_updateSuggestedPriority);
    _descriptionController.removeListener(_updateSuggestedPriority);
    _taskController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateSuggestedPriority() {
    if (_taskController.text.isNotEmpty) {
      final suggestedPriority = PrioritySuggestionService.suggestPriority(
        dueDate: selectedDate != null ? _getDueDateTime() : null,
        category: selectedCategory,
        title: _taskController.text,
        description: _descriptionController.text,
      );

      if (suggestedPriority != selectedPriority) {
        setState(() {
          selectedPriority = suggestedPriority;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'New Task',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        labelText: 'Task title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                        prefixIcon: Icon(Icons.task_alt_rounded, size: 20.w),
                      ),
                      autofocus: true,
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                        prefixIcon: Icon(Icons.description_rounded, size: 20.w),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16.h),
                    Column(
                      children: [
                        DropdownButtonFormField<TaskPriority>(
                          value: selectedPriority,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                            ),
                            prefixIcon: Icon(
                              Icons.priority_high_rounded,
                              size: 20.w,
                            ),
                            suffixIcon: Tooltip(
                              message: 'Auto-suggested based on task details',
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 16.w,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          items: TaskPriority.values.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    IconUtils.getPriorityIcon(priority),
                                    color: ColorUtils.getPriorityColor(
                                      priority,
                                    ),
                                    size: 16.w,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _getPriorityShortName(priority),
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedPriority = value!;
                            });
                          },
                        ),
                        SizedBox(height: 16.h),
                        DropdownButtonFormField<TaskCategory>(
                          value: selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                            ),
                            prefixIcon: Icon(
                              Icons.category_rounded,
                              size: 20.w,
                            ),
                          ),
                          items: TaskCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    IconUtils.getCategoryIcon(category),
                                    color: ColorUtils.getCategoryColor(
                                      category,
                                    ),
                                    size: 16.w,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _getCategoryShortName(category),
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                              _updateSuggestedPriority();
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() {
                                  selectedDate = date;
                                  _updateSuggestedPriority();
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(12.w),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 20.w,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                                fontSize: 12.sp,
                                              ),
                                        ),
                                        Text(
                                          selectedDate == null
                                              ? 'No date'
                                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14.sp,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16.w,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  selectedTime = time;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(12.w),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 20.w,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Time',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                                fontSize: 12.sp,
                                              ),
                                        ),
                                        Text(
                                          selectedTime == null
                                              ? 'No time'
                                              : selectedTime!.format(context),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14.sp,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16.w,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedDate != null || selectedTime != null) ...[
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.w),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20.w,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reminder Set',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.sp,
                                        ),
                                  ),
                                  Text(
                                    _getReminderText(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 14.sp,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    child: Text('Cancel', style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_taskController.text.isNotEmpty) {
                        final dueDateTime = _getDueDateTime();
                        widget.onAddTask(
                          _taskController.text,
                          _descriptionController.text,
                          dueDateTime,
                          selectedPriority,
                          selectedCategory,
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    child: Text('Add Task', style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _getDueDateTime() {
    if (selectedDate == null) return null;

    if (selectedTime != null) {
      return DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
    }

    return selectedDate;
  }

  String _getReminderText() {
    if (selectedDate == null && selectedTime == null) return '';

    if (selectedDate != null && selectedTime != null) {
      final dateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${selectedTime!.format(context)}';
    } else if (selectedDate != null) {
      return '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} (all day)';
    } else {
      return 'Today at ${selectedTime!.format(context)}';
    }
  }

  String _getPriorityShortName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  String _getCategoryShortName(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.creative:
        return 'Creative';
      case TaskCategory.travel:
        return 'Travel';
      case TaskCategory.shopping:
        return 'Shopping';
      case TaskCategory.family:
        return 'Family';
    }
  }
}
