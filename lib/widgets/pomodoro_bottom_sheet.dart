import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/task.dart';
import '../widgets/pomodoro_timer.dart';

class PomodoroBottomSheet extends StatelessWidget {
  final Task task;

  const PomodoroBottomSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ),
          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'Study Session',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24.sp,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          // Timer
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: PomodoroTimer(task: task),
            ),
          ),
        ],
      ),
    );
  }
}
