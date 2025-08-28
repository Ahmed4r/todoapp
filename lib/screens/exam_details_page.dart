import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/exam_countdown_service.dart';
import '../models/exam.dart';

class ExamDetailsPage extends StatefulWidget {
  final Exam exam;

  const ExamDetailsPage({super.key, required this.exam});

  @override
  State<ExamDetailsPage> createState() => _ExamDetailsPageState();
}

class _ExamDetailsPageState extends State<ExamDetailsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverFillRemaining(
            child: Column(
              children: [
                _buildCountdownCard(context),
                _buildTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(context),
                      _buildStudyPlanTab(context),
                      _buildProgressTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: widget.exam.urgency.color,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.exam.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.exam.urgency.color,
                widget.exam.urgency.color.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(widget.exam.type.icon, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  widget.exam.subject,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('تعديل')],
              ),
              onTap: () => _editExam(context),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => _deleteExam(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdownCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeUntil = widget.exam.timeUntilExam;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
            widget.exam.isPassed
                ? 'انتهى الامتحان'
                : widget.exam.isToday
                ? 'الامتحان اليوم!'
                : 'العد التنازلي',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          if (!widget.exam.isPassed) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
            const SizedBox(height: 16),
          ],
          Text(
            _formatDateTime(widget.exam.examDate),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(BuildContext context, String value, String unit) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: TextStyle(fontSize: 12, color: colorScheme.onPrimaryContainer),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        tabs: const [
          Tab(icon: Icon(Icons.info), text: 'نظرة عامة'),
          Tab(icon: Icon(Icons.schedule), text: 'خطة المراجعة'),
          Tab(icon: Icon(Icons.analytics), text: 'التقدم'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(context),
        const SizedBox(height: 16),
        _buildTopicsCard(context),
        const SizedBox(height: 16),
        _buildDetailsCard(context),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'معلومات الامتحان',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('المادة', widget.exam.subject),
            _buildInfoRow('النوع', widget.exam.type.arabicName),
            _buildInfoRow('الصعوبة', widget.exam.difficulty.arabicName),
            _buildInfoRow('التاريخ', _formatDate(widget.exam.examDate)),
            _buildInfoRow('الوقت', _formatTime(widget.exam.examDate)),
            _buildInfoRow('الحالة', widget.exam.urgency.arabicName),
            if (widget.exam.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'الوصف:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(widget.exam.description),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTopicsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.topic, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'المواضيع المطلوبة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.exam.topics.isEmpty)
              const Text('لم يتم تحديد مواضيع بعد')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.exam.topics.map((topic) {
                  return Chip(
                    label: Text(topic),
                    backgroundColor: colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'خطة المراجعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'ساعات المراجعة المطلوبة',
              '${widget.exam.studyHoursNeeded} ساعة',
            ),
            _buildInfoRow(
              'ساعات المراجعة المكتملة',
              '${widget.exam.studyHoursCompleted} ساعة',
            ),
            _buildInfoRow(
              'ساعات يومية مطلوبة',
              '${widget.exam.dailyStudyHoursNeeded.toStringAsFixed(1)} ساعة',
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تقدم المراجعة',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${(widget.exam.studyProgress * 100).round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.exam.studyProgress,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.exam.studyProgress >= 0.8
                        ? Colors.green
                        : widget.exam.studyProgress >= 0.5
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyPlanTab(BuildContext context) {
    return Consumer<ExamCountdownService>(
      builder: (context, service, child) {
        final studySessions = service.studySessions
            .where((session) => session.examId == widget.exam.id)
            .toList();

        if (studySessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لم يتم إنشاء خطة مراجعة بعد',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _generateStudyPlan(context),
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('إنشاء خطة مراجعة'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: studySessions.length,
          itemBuilder: (context, index) {
            final session = studySessions[index];
            return _buildStudySessionCard(context, session);
          },
        );
      },
    );
  }

  Widget _buildStudySessionCard(BuildContext context, StudySession session) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: session.sessionType.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            session.sessionType.icon,
            color: session.sessionType.color,
          ),
        ),
        title: Text(session.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateTime(session.scheduledDate),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            if (session.topics.isNotEmpty)
              Text(
                'المواضيع: ${session.topics.join(", ")}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${session.plannedDurationMinutes} د',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (session.isCompleted)
              Icon(Icons.check_circle, color: Colors.green, size: 16),
          ],
        ),
        onTap: session.isCompleted
            ? null
            : () => _startStudySession(context, session),
      ),
    );
  }

  Widget _buildProgressTab(BuildContext context) {
    return Consumer<ExamCountdownService>(
      builder: (context, service, child) {
        final analytics = service.getExamAnalytics(widget.exam.id);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProgressOverviewCard(context, analytics),
            const SizedBox(height: 16),
            _buildStudyStatsCard(context, analytics),
          ],
        );
      },
    );
  }

  Widget _buildProgressOverviewCard(
    BuildContext context,
    Map<String, dynamic> analytics,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نظرة عامة على التقدم',
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
                  child: _buildProgressItem(
                    context,
                    '${((analytics['studyProgress'] as double) * 100).round()}%',
                    'تقدم المراجعة',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildProgressItem(
                    context,
                    '${analytics['totalStudyHours'].toStringAsFixed(1)}س',
                    'ساعات المراجعة',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildProgressItem(
                    context,
                    '${analytics['daysUntilExam']}',
                    'أيام متبقية',
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(
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

  Widget _buildStudyStatsCard(
    BuildContext context,
    Map<String, dynamic> analytics,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات جلسات المراجعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('إجمالي الجلسات', '${analytics['totalSessions']}'),
            _buildInfoRow(
              'الجلسات المكتملة',
              '${analytics['completedSessions']}',
            ),
            _buildInfoRow(
              'معدل الإنجاز',
              '${((analytics['sessionProgress'] as double) * 100).round()}%',
            ),
            _buildInfoRow(
              'الساعات المطلوبة يومياً',
              '${analytics['dailyHoursNeeded'].toStringAsFixed(1)} ساعة',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (widget.exam.isPassed) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => _startQuickStudySession(context),
      icon: const Icon(Icons.play_arrow),
      label: const Text('بدء المراجعة'),
    );
  }

  void _editExam(BuildContext context) {
    // TODO: Implement edit exam functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة التعديل ستكون متاحة قريباً')),
    );
  }

  void _deleteExam(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الامتحان'),
        content: const Text('هل أنت متأكد من حذف هذا الامتحان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ExamCountdownService>().deleteExam(widget.exam.id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الامتحان'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generateStudyPlan(BuildContext context) async {
    final service = context.read<ExamCountdownService>();
    final studyPlan = service.generateStudyPlan(widget.exam);

    for (final session in studyPlan) {
      await service.addStudySession(session);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء خطة المراجعة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _startStudySession(BuildContext context, StudySession session) {
    // TODO: Implement study session timer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة مؤقت الجلسة ستكون متاحة قريباً')),
    );
  }

  void _startQuickStudySession(BuildContext context) {
    // TODO: Implement quick study session
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة الجلسة السريعة ستكون متاحة قريباً')),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} في ${_formatTime(dateTime)}';
  }
}
