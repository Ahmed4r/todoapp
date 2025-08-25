import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/task.dart';
import '../utils/color_utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final int index;
  final Animation<double> animation;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.animation,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value) * (index + 1)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.w),
                  onTap: onTap,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.w),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10.w,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildCheckbox(),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5)
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      fontSize: 16.sp,
                                    ),
                              ),
                              if (task.description.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  task.description,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        fontSize: 14.sp,
                                      ),
                                ),
                              ],
                              if (task.dueDate != null) ...[
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 14.w,
                                      color: ColorUtils.getDueDateColor(task),
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        ColorUtils.getDueDateTimeText(task),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ColorUtils.getDueDateColor(
                                                task,
                                              ),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12.sp,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  _buildCategoryChip(),
                                  SizedBox(width: 8.w),
                                  _buildPriorityChip(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: onEdit,
                              icon: Icon(Icons.edit_outlined, size: 20.w),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: 'Edit task',
                            ),
                            IconButton(
                              onPressed: onDelete,
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20.w,
                              ),
                              color: const Color(0xFFFF3B30),
                              tooltip: 'Delete task',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckbox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: task.isCompleted
              ? const Color(0xFF34C759)
              : Colors.grey.withValues(alpha: 0.3),
          width: 2.w,
        ),
        color: task.isCompleted ? const Color(0xFF34C759) : Colors.transparent,
      ),
      child: task.isCompleted
          ? Icon(Icons.check_rounded, size: 16.w, color: Colors.white)
          : null,
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: ColorUtils.getCategoryColor(
          task.category,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Text(
        _getCategoryShortName(task.category),
        style: TextStyle(
          color: ColorUtils.getCategoryColor(task.category),
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  Widget _buildPriorityChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: ColorUtils.getPriorityColor(
          task.priority,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Text(
        _getPriorityShortName(task.priority),
        style: TextStyle(
          color: ColorUtils.getPriorityColor(task.priority),
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
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
