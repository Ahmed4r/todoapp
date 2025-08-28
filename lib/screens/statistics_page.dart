import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_insights_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with TickerProviderStateMixin {
  UserAnalytics? _analytics;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadStatistics();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadStatistics() async {
    try {
      // Use the same analytics gathering method from AI insights
      final analytics = await _gatherUserAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Copy the analytics gathering method from AI insights service
  Future<UserAnalytics> _gatherUserAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();

    // Calculate daily productivity for last 7 days
    List<int> dailyProductivity = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final pomodoroCount = prefs.getInt('pomodoro_count_$dateStr') ?? 0;
      final taskCount = prefs.getInt('completed_tasks_$dateStr') ?? 0;
      dailyProductivity.add(pomodoroCount + taskCount);
    }

    // Calculate streak
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final dailyTotal =
          (prefs.getInt('pomodoro_count_$dateStr') ?? 0) +
          (prefs.getInt('completed_tasks_$dateStr') ?? 0);

      if (dailyTotal > 0) {
        if (i == 0) currentStreak++;
        tempStreak++;
        longestStreak = (longestStreak > tempStreak)
            ? longestStreak
            : tempStreak;
      } else {
        if (i == 0) break;
        tempStreak = 0;
      }
    }

    // Get most productive hour (simplified)
    final mostProductiveHour = prefs.getInt('most_productive_hour') ?? 9;

    return UserAnalytics(
      totalPomodoroSessions: prefs.getInt('total_pomodoro_sessions') ?? 0,
      totalCompletedTasks: prefs.getInt('total_completed_tasks') ?? 0,
      totalStudyTimeMinutes: prefs.getInt('total_study_time_minutes') ?? 0,
      averageSessionLength: prefs.getDouble('average_session_length') ?? 25.0,
      mostProductiveHour: mostProductiveHour,
      dailyProductivity: dailyProductivity,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      taskCategories: {
        'study': prefs.getInt('category_study') ?? 0,
        'work': prefs.getInt('category_work') ?? 0,
        'personal': prefs.getInt('category_personal') ?? 0,
      },
      focusEfficiency: prefs.getDouble('focus_efficiency') ?? 0.75,
      breaksTaken: prefs.getInt('total_breaks_taken') ?? 0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                    colorScheme.tertiaryContainer,
                  ]
                : [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                    const Color(0xFF047857),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingWidget()
                    : _buildStatisticsContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerTextColor = isDark
        ? theme.colorScheme.onPrimaryContainer
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: headerTextColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإحصائيات',
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: headerTextColor,
                  ),
                ),
                Text(
                  'تقرير شامل عن تقدمك',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: headerTextColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadStatistics,
            icon: Icon(Icons.refresh_rounded, color: headerTextColor, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loadingTextColor = isDark
        ? theme.colorScheme.onPrimaryContainer
        : Colors.white;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(loadingTextColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'جاري تحميل إحصائياتك...',
            style: TextStyle(color: loadingTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent() {
    if (_analytics == null) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 20),
            _buildProductivityChart(),
            const SizedBox(height: 20),
            _buildStreakCard(),
            const SizedBox(height: 20),
            _buildCategoryBreakdown(),
            const SizedBox(height: 20),
            _buildTimeAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'جلسات البومودورو',
            value: '${_analytics!.totalPomodoroSessions}',
            icon: Icons.timer_outlined,
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'المهام المكتملة',
            value: '${_analytics!.totalCompletedTasks}',
            icon: Icons.task_alt,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityChart() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'الإنتاجية الأسبوعية',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSimpleChart(),
        ],
      ),
    );
  }

  Widget _buildSimpleChart() {
     final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxValue = _analytics!.dailyProductivity.reduce(
      (a, b) => a > b ? a : b,
    );
    if (maxValue == 0) {
      return const Text(
        'لا توجد بيانات كافية لعرض الرسم البياني',
        style: TextStyle(color: Color(0xFF6B7280)),
      );
    }

    final days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final value = _analytics!.dailyProductivity[index];
          final height = (value / maxValue) * 150;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: height.clamp(20.0, 150.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF10B981).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStreakCard() {
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakStat(
                'السلسلة الحالية',
                '${_analytics!.currentStreak}',
                'أيام',
                Icons.local_fire_department,
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStreakStat(
                'أطول سلسلة',
                '${_analytics!.longestStreak}',
                'أيام',
                Icons.emoji_events,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(
    
    String title,
    String value,
    String unit,
    IconData icon,
  ) {
    
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          unit,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
     final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = _analytics!.taskCategories.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'لا توجد مهام مكتملة بعد',
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع المهام حسب الفئة',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          ..._analytics!.taskCategories.entries.map((entry) {
            final percentage = (entry.value / total * 100).round();
            return _buildCategoryBar(entry.key, entry.value, percentage);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String category, int count, int percentage) {
     final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryNames = {'study': 'دراسة', 'work': 'عمل', 'personal': 'شخصي'};

    final colors = {
      'study': const Color(0xFF6366F1),
      'work': const Color(0xFF10B981),
      'personal': const Color(0xFFEF4444),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryNames[category] ?? category,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '$count ($percentage%)',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              colors[category] ?? const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAnalysis() {
     final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تحليل الوقت',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _buildTimeMetric(
            'أكثر الساعات إنتاجية',
            '${_analytics!.mostProductiveHour}:00',
            Icons.schedule,
            const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 16),
          _buildTimeMetric(
            'متوسط طول الجلسة',
            '${_analytics!.averageSessionLength.toStringAsFixed(1)} دقيقة',
            Icons.timer,
            const Color(0xFF06B6D4),
          ),
          const SizedBox(height: 16),
          _buildTimeMetric(
            'كفاءة التركيز',
            '${(_analytics!.focusEfficiency * 100).toStringAsFixed(1)}%',
            Icons.psychology,
            const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
     final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 16),
                Text(
                  'خطأ في تحميل الإحصائيات',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadStatistics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'إعادة المحاولة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
