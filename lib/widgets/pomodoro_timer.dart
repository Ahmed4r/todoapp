import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../services/pomodoro_service.dart';
import '../models/task.dart';

class PomodoroTimer extends StatefulWidget {
  final Task task;
  final VoidCallback? onComplete;

  const PomodoroTimer({super.key, required this.task, this.onComplete});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer>
    with SingleTickerProviderStateMixin {
  late PomodoroService _pomodoroService;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pomodoroService = PomodoroService();
    _pomodoroService.startNewSession(widget.task);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pomodoroService.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pomodoroService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimerHeader(),
          SizedBox(height: 24.h),
          _buildTimerCircle(),
          SizedBox(height: 24.h),
          _buildControls(),
          if (_pomodoroService.currentSession != null) ...[
            SizedBox(height: 16.h),
            _buildStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerHeader() {
    String statusText = 'Focus Time';
    Color statusColor = Theme.of(context).colorScheme.primary;

    switch (_pomodoroService.state) {
      case PomodoroState.break_time:
        statusText = 'Break Time';
        statusColor = const Color(0xFF34C759);
        break;
      case PomodoroState.paused:
        statusText = 'Paused';
        statusColor = Colors.orange;
        break;
      case PomodoroState.completed:
        statusText = 'Completed';
        statusColor = const Color(0xFF34C759);
        break;
      default:
        break;
    }

    return Column(
      children: [
        Text(
          statusText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.task.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            fontSize: 16.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimerCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200.w,
          height: 200.w,
          child: TweenAnimationBuilder(
            tween: Tween(begin: 0.0, end: _pomodoroService.progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, double progress, child) {
              return CustomPaint(
                painter: TimerPainter(
                  progress: progress,
                  color: _getProgressColor(),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                ),
              );
            },
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _pomodoroService.formattedTime,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 48.sp,
              ),
            ),
            if (_pomodoroService.currentSession?.completedPomodoros != null)
              Text(
                '${_pomodoroService.currentSession!.completedPomodoros} pomodoros completed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _getProgressColor() {
    switch (_pomodoroService.state) {
      case PomodoroState.break_time:
        return const Color(0xFF34C759);
      case PomodoroState.paused:
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Future<void> _showStopConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'End Session?',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to end this study session? Your progress will be saved.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              Navigator.pop(context); // Close the bottom sheet
            },
            child: const Text(
              'End Session',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      _pomodoroService.stop();
    }
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_pomodoroService.state == PomodoroState.ready ||
            _pomodoroService.state == PomodoroState.paused)
          _buildControlButton(
            icon: Icons.play_arrow_rounded,
            color: const Color(0xFF34C759),
            onPressed: _pomodoroService.start,
          ),
        if (_pomodoroService.state == PomodoroState.running)
          _buildControlButton(
            icon: Icons.pause_rounded,
            color: Colors.orange,
            onPressed: _pomodoroService.pause,
          ),
        SizedBox(width: 16.w),
        if (_pomodoroService.state != PomodoroState.break_time)
          _buildControlButton(
            icon: Icons.stop_rounded,
            color: Colors.red,
            onPressed: () => _showStopConfirmation(context),
          ),
        if (_pomodoroService.state == PomodoroState.break_time) ...[
          SizedBox(width: 16.w),
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            color: Colors.blue,
            onPressed: _pomodoroService.skipBreak,
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 32.w),
        padding: EdgeInsets.all(12.w),
      ),
    );
  }

  Widget _buildStats() {
    final session = _pomodoroService.currentSession!;
    final focusMinutes = session.totalFocusTimeInSeconds ~/ 60;
    final breakMinutes = session.totalBreakTimeInSeconds ~/ 60;
    final totalMinutes = session.totalSessionTimeInSeconds ~/ 60;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.w),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Focus Time',
                '${focusMinutes}m',
                Icons.timer_outlined,
                Theme.of(context).colorScheme.primary,
              ),
              _buildStatItem(
                'Break Time',
                '${breakMinutes}m',
                Icons.coffee_rounded,
                const Color(0xFF34C759),
              ),
              _buildStatItem(
                'Pomodoros',
                '${session.completedPomodoros}',
                Icons.check_circle_outline,
                Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16.w,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: 8.w),
              Text(
                'Total Session Time: ${totalMinutes}m',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    final statColor = color ?? Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Icon(icon, color: statColor, size: 24.w),
        SizedBox(height: 8.h),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: statColor,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  TimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;

    // Draw background circle
    paint.color = backgroundColor;
    canvas.drawCircle(center, radius, paint);

    // Draw progress arc
    paint.color = color;
    paint.strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
