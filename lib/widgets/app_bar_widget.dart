import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
                  'Tasks',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 32.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$completedTasks of $totalTasks completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
