import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/exam_countdown_service.dart';
import '../models/exam.dart';
import 'add_exam_page.dart';
import 'exam_details_page.dart';

class ExamCountdownPage extends StatefulWidget {
  const ExamCountdownPage({super.key});

  @override
  State<ExamCountdownPage> createState() => _ExamCountdownPageState();
}

class _ExamCountdownPageState extends State<ExamCountdownPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startClockTimer();

    // Initialize service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamCountdownService>().initialize();
    });
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'وضع العد التنازلي للامتحانات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'القادمة'),
            Tab(icon: Icon(Icons.today), text: 'اليوم'),
            Tab(icon: Icon(Icons.analytics), text: 'الإحصائيات'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddExamSheet(context),
            icon: const Icon(Icons.add),
            tooltip: 'إضافة امتحان',
          ),
        ],
      ),
      body: Column(
        children: [
          // Digital Clock
          _buildDigitalClock(context),
          // Tabs Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingExamsTab(context),
                _buildTodayExamsTab(context),
                _buildAnalyticsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalClock(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeFormat = TimeOfDay.fromDateTime(_currentTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${timeFormat.hour.toString().padLeft(2, '0')}:${timeFormat.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(_currentTime),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamsTab(BuildContext context) {
    return Consumer<ExamCountdownService>(
      builder: (context, service, child) {
        final upcomingExams = service.upcomingExams;

        if (upcomingExams.isEmpty) {
          return _buildEmptyState(
            context,
            'لا توجد امتحانات قادمة',
            'أضف امتحاناتك لبدء العد التنازلي',
            Icons.event_available,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcomingExams.length,
          itemBuilder: (context, index) {
            final exam = upcomingExams[index];
            return _buildExamCard(context, exam);
          },
        );
      },
    );
  }

  Widget _buildTodayExamsTab(BuildContext context) {
    return Consumer<ExamCountdownService>(
      builder: (context, service, child) {
        final todayExams = service.todayExams;

        if (todayExams.isEmpty) {
          return _buildEmptyState(
            context,
            'لا توجد امتحانات اليوم',
            'استرح واستعد للامتحانات القادمة',
            Icons.free_breakfast,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: todayExams.length,
          itemBuilder: (context, index) {
            final exam = todayExams[index];
            return _buildTodayExamCard(context, exam);
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab(BuildContext context) {
    return Consumer<ExamCountdownService>(
      builder: (context, service, child) {
        final analytics = service.getAllExamAnalytics();

        if (analytics.isEmpty) {
          return _buildEmptyState(
            context,
            'لا توجد إحصائيات',
            'أضف امتحانات وابدأ المراجعة لرؤية التقدم',
            Icons.analytics,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOverallStatsCard(context, analytics),
            const SizedBox(height: 16),
            ...analytics.map(
              (analytic) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildExamAnalyticsCard(context, analytic),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExamCard(BuildContext context, Exam exam) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeUntil = exam.timeUntilExam;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToExamDetails(context, exam),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: exam.urgency.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      exam.type.icon,
                      color: exam.urgency.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          exam.subject,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: exam.urgency.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      exam.urgency.arabicName,
                      style: TextStyle(
                        color: exam.urgency.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Countdown Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCountdownUnit(
                      context,
                      timeUntil.inDays.toString(),
                      'يوم',
                    ),
                    _buildCountdownUnit(
                      context,
                      (timeUntil.inHours % 24).toString(),
                      'ساعة',
                    ),
                    _buildCountdownUnit(
                      context,
                      (timeUntil.inMinutes % 60).toString(),
                      'دقيقة',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تقدم المراجعة',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${(exam.studyProgress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: exam.studyProgress,
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      exam.studyProgress >= 0.8
                          ? Colors.green
                          : exam.studyProgress >= 0.5
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayExamCard(BuildContext context, Exam exam) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.errorContainer,
      child: InkWell(
        onTap: () => _navigateToExamDetails(context, exam),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.today,
                    color: colorScheme.onErrorContainer,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                        Text(
                          exam.subject,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer.withOpacity(
                              0.8,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'الامتحان اليوم - ${_formatTime(exam.examDate)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _navigateToExamDetails(context, exam),
                icon: const Icon(Icons.visibility),
                label: const Text('عرض التفاصيل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownUnit(BuildContext context, String value, String unit) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildOverallStatsCard(
    BuildContext context,
    List<Map<String, dynamic>> analytics,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final totalExams = analytics.length;
    final totalStudyHours = analytics
        .map((a) => a['totalStudyHours'] as double)
        .fold<double>(0.0, (sum, hours) => sum + hours);
    final avgProgress = analytics.isEmpty
        ? 0.0
        : analytics
                  .map((a) => a['studyProgress'] as double)
                  .fold<double>(0.0, (sum, progress) => sum + progress) /
              totalExams;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات عامة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    totalExams.toString(),
                    'إجمالي الامتحانات',
                    Icons.event,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '${totalStudyHours.toStringAsFixed(1)} ساعة',
                    'ساعات المراجعة',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '${(avgProgress * 100).round()}%',
                    'متوسط التقدم',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExamAnalyticsCard(
    BuildContext context,
    Map<String, dynamic> analytic,
  ) {
    final exam = analytic['exam'] as Exam;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(exam.type.icon, color: exam.urgency.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exam.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${exam.daysUntilExam} يوم',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticItem(
                    context,
                    '${((analytic['studyProgress'] as double) * 100).round()}%',
                    'التقدم',
                  ),
                ),
                Expanded(
                  child: _buildAnalyticItem(
                    context,
                    '${analytic['totalStudyHours'].toStringAsFixed(1)}س',
                    'ساعات المراجعة',
                  ),
                ),
                Expanded(
                  child: _buildAnalyticItem(
                    context,
                    '${analytic['completedSessions']}/${analytic['totalSessions']}',
                    'الجلسات',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticItem(BuildContext context, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddExamSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة امتحان'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExamSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddExamPage(),
    );
  }

  void _navigateToExamDetails(BuildContext context, Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExamDetailsPage(exam: exam)),
    );
  }

  String _formatDate(DateTime date) {
    const arabicMonths = [
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

    const arabicDays = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    final dayName = arabicDays[date.weekday - 1];
    final monthName = arabicMonths[date.month - 1];

    return '$dayName، ${date.day} $monthName ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }
}
