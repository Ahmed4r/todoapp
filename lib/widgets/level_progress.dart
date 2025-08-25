import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/pomodoro_service.dart';

class LevelProgress extends StatelessWidget {
  final PomodoroService pomodoroService;

  const LevelProgress({super.key, required this.pomodoroService});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w), // Reduced from 16.w
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.w), // Reduced from 16.w
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber, size: 24.w),
              SizedBox(width: 8.w),
              Text(
                'Level ${pomodoroService.level}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.w),
            child: LinearProgressIndicator(
              value: pomodoroService.levelProgress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${pomodoroService.currentXP} / ${pomodoroService.xpToNextLevel} XP',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
