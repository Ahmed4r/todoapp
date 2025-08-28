import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/motivational_message_service.dart';
import '../services/pomodoro_service.dart';
import '../widgets/motivational_message_widget.dart';

class DailyMotivationPage extends StatefulWidget {
  const DailyMotivationPage({super.key});

  @override
  State<DailyMotivationPage> createState() => _DailyMotivationPageState();
}

class _DailyMotivationPageState extends State<DailyMotivationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PomodoroService _pomodoroService = PomodoroService();

  int pomodoroCount = 0;
  int tasksCount = 0;
  bool isLoading = true;

  // Cache additional inspirational content
  String? _cachedQuranVerse;
  String? _cachedHadith;
  String? _cachedQuote;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadDailyProgress();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );
  }

  Future<void> _loadDailyProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Get real pomodoro count from pomodoro service
      final realPomodoroCount = await _pomodoroService.getTodayPomodoroCount();

      // Load or generate daily inspirational content
      String quranVerse = prefs.getString('quran_verse_$today') ?? '';
      String hadith = prefs.getString('hadith_$today') ?? '';
      String quote = prefs.getString('quote_$today') ?? '';

      // Generate new content if not cached for today
      if (quranVerse.isEmpty) {
        quranVerse = MotivationalMessageService.getRandomQuranVerse();
        await prefs.setString('quran_verse_$today', quranVerse);
      }

      if (hadith.isEmpty) {
        hadith = MotivationalMessageService.getRandomHadith();
        await prefs.setString('hadith_$today', hadith);
      }

      if (quote.isEmpty) {
        quote = MotivationalMessageService.getRandomQuote();
        await prefs.setString('quote_$today', quote);
      }

      setState(() {
        pomodoroCount = realPomodoroCount;
        tasksCount = prefs.getInt('completed_tasks_$today') ?? 0;

        // Cache additional inspirational content for the day
        _cachedQuranVerse = quranVerse;
        _cachedHadith = hadith;
        _cachedQuote = quote;

        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pomodoroService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الرسالة اليومية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _animationController.reset();
              _loadDailyProgress();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContent(),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Header
          _buildDateHeader(),

          SizedBox(height: 24.h),

          // Main Motivational Message
          MotivationalMessageWidget(
            pomodoroCount: pomodoroCount,
            tasksCount: tasksCount,
          ),

          SizedBox(height: 24.h),

          // Progress Summary
          _buildProgressSummary(),

          SizedBox(height: 24.h),

          // Additional Inspirations
          _buildAdditionalContent(),

          SizedBox(height: 24.h),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    final arabicDays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            arabicDays[now.weekday - 1],
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${now.day} ${arabicMonths[now.month - 1]} ${now.year}',
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    final totalProgress = pomodoroCount + tasksCount;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص اليوم',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  context: context,
                  icon: Icons.timer,
                  title: 'جلسات البومودورو',
                  count: pomodoroCount,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF10B981) 
                    : Colors.green,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildProgressCard(
                  context: context,
                  icon: Icons.task_alt,
                  title: 'المهام المكتملة',
                  count: tasksCount,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF3B82F6) 
                    : Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          LinearProgressIndicator(
            value: totalProgress / 10, // Max 10 for full progress
            backgroundColor: Theme.of(
              context,
            ).colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              totalProgress >= 7
                  ? (Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF10B981) 
                      : Colors.green)
                  : totalProgress >= 4
                  ? (Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFFF59E0B) 
                      : Colors.orange)
                  : (Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFFEF4444) 
                      : Colors.red),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _getProgressMessage(totalProgress),
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'إلهام إضافي',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 12.h),
        _buildInspirationCard(
          title: 'آية كريمة',
          content: _cachedQuranVerse ?? 'جاري التحميل...',
          icon: Icons.menu_book,
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF10B981) 
            : Colors.green,
        ),
        SizedBox(height: 12.h),
        _buildInspirationCard(
          title: 'حديث شريف',
          content: _cachedHadith ?? 'جاري التحميل...',
          icon: Icons.record_voice_over,
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF3B82F6) 
            : Colors.blue,
        ),
        SizedBox(height: 12.h),
        _buildInspirationCard(
          title: 'حكمة',
          content: _cachedQuote ?? 'جاري التحميل...',
          icon: Icons.format_quote,
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFFF59E0B) 
            : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInspirationCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.home),
            label: const Text('العودة للرئيسية'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Share functionality
              _shareMotivationalMessage();
            },
            icon:  Icon(Icons.adaptive.share),
            label: const Text('مشاركة'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getProgressMessage(int totalProgress) {
    if (totalProgress >= 7) {
      return 'إنجاز رائع! أنت في المسار الصحيح 🌟';
    } else if (totalProgress >= 4) {
      return 'أداء جيد، يمكنك تحقيق المزيد 💪';
    } else if (totalProgress >= 1) {
      return 'بداية طيبة، استمر في التقدم 👍';
    } else {
      return 'ابدأ رحلتك اليوم واجعلها مثمرة 🚀';
    }
  }

  void _shareMotivationalMessage() {
    final message = MotivationalMessageService.generateDailyMessage(
      pomodoroCount: pomodoroCount,
      tasksCount: tasksCount,
    );

    // Implement share functionality here
    // You can use the share_plus package
    // For now, just show a snackbar
    debugPrint('Sharing message: ${message.message}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الرسالة للحافظة'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
