import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/chatbot_service.dart';
import '../models/task.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  List<Task> _currentTasks = [];
  List<String> _suggestedResponses = [];

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _initializeChatbot();
    _loadCurrentTasks();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatbot() async {
    await ChatbotService.initialize();
    setState(() {
      _messages = ChatbotService.messages;
      _isInitialized = true;
    });

    _updateSuggestedResponses();

    // Add welcome message if this is the first time
    if (_messages.isEmpty) {
      await _addWelcomeMessage();
    }

    _scrollToBottom();
  }

  Future<void> _loadCurrentTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('tasks') ?? [];
      _currentTasks = tasksJson
          .map((json) => Task.fromJson(jsonDecode(json)))
          .toList();
      _updateSuggestedResponses();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  void _updateSuggestedResponses() {
    final hasOverdue = _currentTasks.any(
      (task) =>
          !task.isCompleted &&
          task.dueDate != null &&
          task.dueDate!.isBefore(DateTime.now()),
    );

    final hasUpcoming = _currentTasks.any(
      (task) =>
          !task.isCompleted &&
          task.dueDate != null &&
          task.dueDate!.difference(DateTime.now()).inDays <= 2,
    );

    setState(() {
      _suggestedResponses = ChatbotService.getSuggestedResponses(
        currentTasks: _currentTasks,
        hasOverdueTasks: hasOverdue,
        hasUpcomingDeadlines: hasUpcoming,
      );
    });
  }

  Future<void> _addWelcomeMessage() async {
    final welcomeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '''🌟 مرحباً بك في المساعد الذكي! 

أنا هنا لمساعدتك في:
• تنظيم وإدارة مهامك
• زيادة إنتاجيتك
• تقديم النصائح والتحفيز
• الإرشاد وفق القيم الإسلامية

كيف يمكنني مساعدتك اليوم؟''',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    setState(() {
      _messages = [..._messages, welcomeMessage];
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    _messageController.clear();
    _fabAnimationController.forward();

    try {
      // Update context with current tasks
      await ChatbotService.updateUserContext({
        'total_tasks': _currentTasks.length,
        'completed_tasks': _currentTasks.where((t) => t.isCompleted).length,
        'overdue_tasks': _currentTasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isBefore(DateTime.now()),
            )
            .length,
        'current_time': DateTime.now().toIso8601String(),
      });

      final response = await ChatbotService.sendMessage(
        message,
        currentTasks: _currentTasks,
        additionalContext: {
          'app_section': 'chatbot',
          'user_timezone': DateTime.now().timeZoneName,
        },
      );

      setState(() {
        _messages = ChatbotService.messages;
        _isLoading = false;
      });

      _updateSuggestedResponses();
      _scrollToBottom();

      // Handle special message types
      if (response.type == MessageType.taskSuggestion &&
          response.metadata != null) {
        _handleTaskSuggestions(response.metadata!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال الرسالة: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      _fabAnimationController.reverse();
    }
  }

  void _handleTaskSuggestions(Map<String, dynamic> metadata) {
    // Show dialog to create suggested tasks
    // This would be implemented based on your task creation flow
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme, isDark),
      body: Column(
        children: [
          Expanded(
            child: _isInitialized
                ? _buildChatView(theme, isDark)
                : _buildLoadingView(theme),
          ),
          _buildSuggestedResponses(theme, isDark),
          _buildMessageInput(theme, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8)]
                : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: theme.colorScheme.onPrimary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المساعد الذكي',
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                Text(
                  'مدعوم بالذكاء الاصطناعي',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showChatOptions,
          icon: Icon(Icons.more_vert, color: theme.colorScheme.onPrimary),
        ),
      ],
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحضير المساعد الذكي...',
            style: GoogleFonts.cairo(
              fontSize: 16.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView(ThemeData theme, bool isDark) {
    if (_messages.isEmpty) {
      return _buildEmptyState(theme, isDark);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator(theme, isDark);
        }

        final message = _messages[index];
        return _buildMessageBubble(message, theme, isDark);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1E3A8A).withOpacity(0.3),
                        const Color(0xFF1D4ED8).withOpacity(0.3),
                      ]
                    : [
                        const Color(0xFF6366F1).withOpacity(0.1),
                        const Color(0xFF8B5CF6).withOpacity(0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 48.sp,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'مرحباً بك في المساعد الذكي',
            style: GoogleFonts.cairo(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'ابدأ محادثة واحصل على نصائح\nذكية لإدارة مهامك وزيادة إنتاجيتك',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    ThemeData theme,
    bool isDark,
  ) {
    final isUser = message.isUser;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatarWidget(theme, isDark, false),
          if (!isUser) SizedBox(width: 8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : (isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.surfaceContainerHigh),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                  bottomLeft: Radius.circular(isUser ? 20.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color:
                          (isUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface)
                              .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) SizedBox(width: 8.w),
          if (isUser) _buildAvatarWidget(theme, isDark, true),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget(ThemeData theme, bool isDark, bool isUser) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: isUser
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18.sp,
        color: isUser ? theme.colorScheme.primary : theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          _buildAvatarWidget(theme, isDark, false),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(theme, 0),
                SizedBox(width: 4.w),
                _buildDot(theme, 1),
                SizedBox(width: 4.w),
                _buildDot(theme, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(ThemeData theme, int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final animation = (value + index * 0.2) % 1.0;
        return Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(
              0.3 + (animation * 0.7),
            ),
            borderRadius: BorderRadius.circular(3.r),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedResponses(ThemeData theme, bool isDark) {
    if (_suggestedResponses.isEmpty || _isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedResponses.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestedResponses[index];
          return Container(
            margin: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () => _sendMessage(suggestion),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  suggestion,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: GoogleFonts.cairo(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                filled: true,
                fillColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 - (_fabAnimation.value * 0.1),
                child: FloatingActionButton.small(
                  onPressed: _isLoading
                      ? null
                      : () => _sendMessage(_messageController.text),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  child: _isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(Icons.send, size: 20.sp),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'قبل ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'قبل ${difference.inHours} ساعة';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChatOptionsSheet(),
    );
  }

  Widget _buildChatOptionsSheet() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.refresh, color: theme.colorScheme.primary),
            title: Text('إعادة تعيين المحادثة'),
            onTap: () {
              Navigator.pop(context);
              _clearChat();
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: Text('حول المساعد الذكي'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين المحادثة'),
        content: const Text('هل أنت متأكد من حذف جميع الرسائل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ChatbotService.clearChatHistory();
              setState(() {
                _messages.clear();
              });
              await _addWelcomeMessage();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعد الذكي'),
        content: const Text(
          'مساعد ذكي مدعوم بتقنية الذكاء الاصطناعي لمساعدتك في إدارة مهامك وزيادة إنتاجيتك وفق القيم الإسلامية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
