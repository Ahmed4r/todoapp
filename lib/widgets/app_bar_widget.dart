import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:todoapp/screens/exam_countdown_page.dart';
import '../screens/pdf_to_summary_page.dart';

class AppBarWidget extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;
  final int completedTasks;
  final int totalTasks;

  const AppBarWidget({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.completedTasks,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Todo',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 32.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$completedTasks of $totalTasks tasks completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          // Exam Countdown Button
          Container(
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10.w,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExamCountdownPage()),
                );
              },
              icon: Icon(
                Icons.calendar_month,
                size: 24.w,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Exam Countdown',
            ),
          ),
          // File Summarizer Button
          Container(
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10.w,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FileSummaryPage(isDarkMode: isDarkMode),
                  ),
                );
              },
              icon: Icon(
                Icons.summarize_rounded,
                size: 24.w,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'File Summarizer',
            ),
          ),
          // Theme Toggle Button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10.w,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: IconButton(
              onPressed: onThemeChanged,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  key: ValueKey(isDarkMode),
                  size: 24.w,
                ),
              ),
              tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
            ),
          ),
        ],
      ),
    );
  }
}
