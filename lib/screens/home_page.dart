import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/edit_task_dialog.dart';
import '../widgets/app_bar_widget.dart';
import '../services/notification_service.dart';

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
      setState(() {
        _tasks.clear();
        _tasks.addAll(
          tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList(),
        );
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
                const Color(0xFF007AFF),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatsCard(
                'Completed',
                completedTasks.toString(),
                Icons.check_circle_rounded,
                const Color(0xFF34C759),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatsCard(
                'Pending',
                pendingTasks.toString(),
                Icons.schedule_rounded,
                const Color(0xFFFF9500),
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
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.6)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
            ),
          ),
        ],
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                  foregroundColor: Colors.white,
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
        foregroundColor: Colors.white,
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
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          updatedAt: DateTime.now(),
        );
        _tasks[index] = updatedTask;

        // Cancel notifications if task is completed
        if (updatedTask.isCompleted) {
          _notificationService.cancelTaskReminder(updatedTask);
        } else if (updatedTask.dueDate != null) {
          // Re-schedule notifications if task is uncompleted
          _notificationService.scheduleTaskReminder(updatedTask);
        }
      }
    });
    _saveTasks();
  }

  void _deleteTask(Task task) {
    // Cancel notifications for the task being deleted
    _notificationService.cancelTaskReminder(task);

    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    _saveTasks();
  }
}
