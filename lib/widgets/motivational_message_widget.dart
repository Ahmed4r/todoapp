import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/motivational_message_service.dart';

class MotivationalMessageWidget extends StatelessWidget {
  final int pomodoroCount;
  final int tasksCount;

  const MotivationalMessageWidget({
    super.key,
    required this.pomodoroCount,
    required this.tasksCount,
  });

  @override
  Widget build(BuildContext context) {
    final message = MotivationalMessageService.generateDailyMessage(
      pomodoroCount: pomodoroCount,
      tasksCount: tasksCount,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: _getGradientByType(message.type, context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and type
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconByType(message.type),
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                _getTypeLabel(message.type),
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.9),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Main message
          Text(
            message.message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              height: 1.5,
              fontFamily: 'Amiri', // Arabic font
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),

          SizedBox(height: 12.h),

          // Source
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  message.source,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.9),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),

          // Progress indicators
          if (pomodoroCount > 0 || tasksCount > 0) ...[
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (pomodoroCount > 0) ...[
                  _buildProgressChip(
                    context: context,
                    icon: Icons.timer,
                    count: pomodoroCount,
                    label: 'بومودورو',
                  ),
                  if (tasksCount > 0) SizedBox(width: 12.w),
                ],
                if (tasksCount > 0)
                  _buildProgressChip(
                    context: context,
                    icon: Icons.task_alt,
                    count: tasksCount,
                    label: 'مهمة',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressChip({
    required BuildContext context,
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            '$count $label',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradientByType(MessageType type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case MessageType.quran:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF166534), // Darker Green for dark mode
                  const Color(0xFF15803D), // Medium Green for dark mode
                ]
              : [
                  const Color(0xFF2E7D32), // Deep Green for light mode
                  const Color(0xFF4CAF50), // Green for light mode
                ],
        );
      case MessageType.hadith:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E3A8A), // Darker Blue for dark mode
                  const Color(0xFF1D4ED8), // Medium Blue for dark mode
                ]
              : [
                  const Color(0xFF1565C0), // Deep Blue for light mode
                  const Color(0xFF2196F3), // Blue for light mode
                ],
        );
      case MessageType.quote:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFFEA580C), // Darker Orange for dark mode
                  const Color(0xFFF59E0B), // Medium Orange for dark mode
                ]
              : [
                  const Color(0xFFE65100), // Deep Orange for light mode
                  const Color(0xFFFF9800), // Orange for light mode
                ],
        );
    }
  }

  IconData _getIconByType(MessageType type) {
    switch (type) {
      case MessageType.quran:
        return Icons.menu_book; // Quran book icon
      case MessageType.hadith:
        return Icons.record_voice_over; // Speaking/Hadith icon
      case MessageType.quote:
        return Icons.format_quote; // Quote icon
    }
  }

  String _getTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.quran:
        return 'آية كريمة';
      case MessageType.hadith:
        return 'حديث شريف';
      case MessageType.quote:
        return 'حكمة';
    }
  }
}

// Compact version for smaller spaces
class CompactMotivationalMessage extends StatelessWidget {
  final int pomodoroCount;
  final int tasksCount;

  const CompactMotivationalMessage({
    super.key,
    required this.pomodoroCount,
    required this.tasksCount,
  });

  @override
  Widget build(BuildContext context) {
    final message = MotivationalMessageService.generateDailyMessage(
      pomodoroCount: pomodoroCount,
      tasksCount: tasksCount,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIconByType(message.type),
            color: Theme.of(context).colorScheme.primary,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconByType(MessageType type) {
    switch (type) {
      case MessageType.quran:
        return Icons.menu_book;
      case MessageType.hadith:
        return Icons.record_voice_over;
      case MessageType.quote:
        return Icons.format_quote;
    }
  }
}
