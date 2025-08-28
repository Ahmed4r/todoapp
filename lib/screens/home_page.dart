import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/edit_task_dialog.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/motivational_message_widget.dart';
import '../screens/daily_motivation_page.dart';
import '../screens/ai_insights_page.dart';
import '../screens/statistics_page.dart';
import '../screens/chatbot_page.dart';
import '../screens/exam_countdown_page.dart';
import '../services/notification_service.dart';
import '../services/pomodoro_service.dart';
import '../services/motivational_message_service.dart';
import '../services/ai_insights_service.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<Task> _tasks = [];
  final NotificationService _notificationService = NotificationService();
  final PomodoroService _pomodoroService = PomodoroService();
  int _todayPomodoroCount = 0;
  int _todayCompletedTasks = 0;

  late AnimationController _fabController;
  late AnimationController _statsController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _statsFadeAnimation;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _statsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeInOut),
    );

    // Add sample tasks
    _tasks.addAll([]);

    _fabController.forward();
    _statsController.forward();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('tasks') ?? [];

      // Load today's pomodoro count
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayPomodoroCount = await _pomodoroService.getTodayPomodoroCount();
      final todayTasksCount = prefs.getInt('completed_tasks_$today') ?? 0;

      setState(() {
        _tasks.clear();
        _tasks.addAll(
          tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList(),
        );
        _todayPomodoroCount = todayPomodoroCount;
        _todayCompletedTasks = todayTasksCount;
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = _tasks
          .map((task) => jsonEncode(task.toJson()))
          .toList();
      await prefs.setStringList('tasks', tasksJson);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            SizedBox(height: 8.h),
            _buildStatsSection(),
            SizedBox(height: 12.h),
            _buildMotivationalMessage(),
            SizedBox(height: 12.h),
            _buildQuickActions(),
            SizedBox(height: 12.h),
            _buildTaskList(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAppBar() {
    return AppBarWidget(
      isDarkMode: widget.isDarkMode,
      onThemeChanged: () {
        widget.onThemeChanged(!widget.isDarkMode);
        _fabController.forward(from: 0.0);
      },
      completedTasks: _tasks.where((task) => task.isCompleted).length,
      totalTasks: _tasks.length,
    );
  }

  Widget _buildStatsSection() {
    final totalTasks = _tasks.length;
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _statsFadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                'Total',
                totalTasks.toString(),
                Icons.checklist_rounded,
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF5AC8FA)
                    : const Color(0xFF007AFF),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatsCard(
                'Completed',
                completedTasks.toString(),
                Icons.check_circle_rounded,
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF30D158)
                    : const Color(0xFF34C759),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatsCard(
                'Pending',
                pendingTasks.toString(),
                Icons.schedule_rounded,
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFFFCC02)
                    : const Color(0xFFFF9500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
            blurRadius: 10.w,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: Icon(icon, color: color, size: 20.w),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 24.sp,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalMessage() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DailyMotivationPage()),
        );
      },
      child: CompactMotivationalMessage(
        pomodoroCount: _todayPomodoroCount,
        tasksCount: _todayCompletedTasks,
      ),
    );
  }

  Widget _buildTaskList() {
    return Expanded(
      child: _tasks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(20.w),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return TaskCard(
                  task: task,
                  index: index,
                  animation: _statsController,
                  onTap: () => _toggleTaskComplete(task),
                  onEdit: () => _showEditTaskDialog(task),
                  onDelete: () => _deleteTask(task),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.05),
                      blurRadius: 20.w,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 60.w,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'No tasks yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Add your first task to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 32.h),
              ElevatedButton.icon(
                onPressed: _showAddTaskDialog,
                icon: Icon(Icons.add_rounded, size: 20.w),
                label: Text('Add Task', style: TextStyle(fontSize: 16.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: Icon(Icons.add_rounded, size: 20.w),
        label: Text('Add Task', style: TextStyle(fontSize: 16.sp)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.w),
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskDialog(onAddTask: _addTask),
    );
  }

  void _showEditTaskDialog(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTaskDialog(
        task: task,
        onUpdateTask: (title, description, dueDate, priority, category) {
          _updateTask(task, title, description, dueDate, priority, category);
        },
      ),
    );
  }

  void _addTask(
    String title,
    String description,
    DateTime? dueDate,
    TaskPriority priority,
    TaskCategory category,
  ) {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      isCompleted: false,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      priority: priority,
      category: category,
    );

    setState(() {
      _tasks.add(newTask);
    });
    _saveTasks();

    // Schedule notification for the new task
    if (dueDate != null) {
      _notificationService.scheduleTaskReminder(newTask);

      // Show immediate notification for confirmation
      _notificationService.showImmediateNotification(
        title: 'Task Added',
        body: 'Reminder set for "$title"',
      );
    }
  }

  void _updateTask(
    Task task,
    String title,
    String description,
    DateTime? dueDate,
    TaskPriority priority,
    TaskCategory category,
  ) {
    // Cancel existing notifications for this task
    _notificationService.cancelTaskReminder(task);

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final updatedTask = task.copyWith(
          title: title,
          description: description,
          dueDate: dueDate,
          priority: priority,
          category: category,
          updatedAt: DateTime.now(),
        );
        _tasks[index] = updatedTask;

        // Schedule new notification if task has due date and is not completed
        if (dueDate != null && !updatedTask.isCompleted) {
          _notificationService.scheduleTaskReminder(updatedTask);
        }
      }
    });
    _saveTasks();
  }

  void _toggleTaskComplete(Task task) {
    final oldProgress = _todayPomodoroCount + _todayCompletedTasks;

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          updatedAt: DateTime.now(),
        );
        _tasks[index] = updatedTask;

        // Update daily task completion count
        if (updatedTask.isCompleted) {
          _todayCompletedTasks++;
          _saveDailyTaskCount();
          _notificationService.cancelTaskReminder(updatedTask);

          // Update analytics for AI insights
          AIInsightsService.updateAnalytics(
            taskCompleted: true,
            productiveHour: DateTime.now().hour,
            taskCategory: updatedTask.category.name,
          );
        } else {
          _todayCompletedTasks = (_todayCompletedTasks - 1)
              .clamp(0, double.infinity)
              .toInt();
          _saveDailyTaskCount();
          if (updatedTask.dueDate != null) {
            // Re-schedule notifications if task is uncompleted
            _notificationService.scheduleTaskReminder(updatedTask);
          }
        }
      }
    });

    _saveTasks();

    // Check if we should refresh the motivational message
    final newProgress = _todayPomodoroCount + _todayCompletedTasks;
    if (MotivationalMessageService.shouldRefreshMessage(
      oldProgress,
      newProgress,
    )) {
      MotivationalMessageService.refreshDailyMessage();
    }
  }

  void _deleteTask(Task task) {
    // Cancel notifications for the task being deleted
    _notificationService.cancelTaskReminder(task);

    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    _saveTasks();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _statsController.dispose();
    _pomodoroService.dispose();
    super.dispose();
  }

  // Method to be called when a pomodoro session is completed
  Future<void> updatePomodoroCount() async {
    final oldProgress = _todayPomodoroCount + _todayCompletedTasks;

    try {
      final newCount = await _pomodoroService.getTodayPomodoroCount();

      setState(() {
        _todayPomodoroCount = newCount;
      });

      debugPrint('Pomodoro count updated: $newCount');

      // Update analytics for AI insights
      if (newCount > oldProgress - _todayCompletedTasks) {
        AIInsightsService.updateAnalytics(
          pomodoroCompleted: true,
          productiveHour: DateTime.now().hour,
          sessionLength: 25.0, // Standard pomodoro length
        );
      }

      // Check if we should refresh the motivational message
      final newProgress = _todayPomodoroCount + _todayCompletedTasks;
      if (MotivationalMessageService.shouldRefreshMessage(
        oldProgress,
        newProgress,
      )) {
        MotivationalMessageService.refreshDailyMessage();
      }
    } catch (e) {
      debugPrint('Error updating pomodoro count: $e');
    }
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // First row with AI Insights and Statistics
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'النصائح الذكية',
                  subtitle: 'تحليل مدعوم بالذكاء الاصطناعي',
                  icon: Icons.psychology_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AIInsightsPage(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildActionCard(
                  title: 'الإحصائيات',
                  subtitle: 'تقرير شامل عن تقدمك',
                  icon: Icons.analytics_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StatisticsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Second row with Exam Countdown and Chatbot
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'عد تنازلي للامتحانات',
                  subtitle: 'راقب امتحاناتك واستعد لها',
                  icon: Icons.schedule,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ExamCountdownPage(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildActionCard(
                  title: 'المساعد الذكي',
                  subtitle: 'دردش واحصل على نصائح شخصية',
                  icon: Icons.smart_toy_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChatbotPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardTextColor = isDark
        ? theme.colorScheme.onPrimaryContainer
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                )
              : gradient,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color:
                  (isDark ? theme.colorScheme.primary : gradient.colors.first)
                      .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cardTextColor, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                color: cardTextColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                color: cardTextColor.withOpacity(0.9),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Save daily task completion count
  Future<void> _saveDailyTaskCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setInt('completed_tasks_$today', _todayCompletedTasks);
      debugPrint('Daily task count saved: $_todayCompletedTasks');
    } catch (e) {
      debugPrint('Error saving daily task count: $e');
    }
  }
}
