import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../services/file_summarization_service.dart' as fs;

class FileSummaryPage extends StatefulWidget {
  final bool isDarkMode;

  const FileSummaryPage({super.key, required this.isDarkMode});

  @override
  State<FileSummaryPage> createState() => _FileSummaryPageState();
}

class _FileSummaryPageState extends State<FileSummaryPage>
    with TickerProviderStateMixin {
  final List<fs.FileSummary> _summaries = [];
  bool _isProcessing = false;
  String _processingFileName = '';
  double _processingProgress = 0.0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedSummaries();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadSavedSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summariesJson = prefs.getStringList('file_summaries') ?? [];
      setState(() {
        _summaries.clear();
        _summaries.addAll(
          summariesJson
              .map((json) => fs.FileSummary.fromJson(jsonDecode(json)))
              .toList(),
        );
      });
    } catch (e) {
      debugPrint('Error loading summaries: $e');
    }
  }

  Future<void> _saveSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summariesJson = _summaries
          .map((summary) => jsonEncode(summary.toJson()))
          .toList();
      await prefs.setStringList('file_summaries', summariesJson);
    } catch (e) {
      debugPrint('Error saving summaries: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            if (_isProcessing) _buildProcessingIndicator(),
            Expanded(
              child: _summaries.isEmpty && !_isProcessing
                  ? _buildEmptyState()
                  : _buildSummariesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'File Summarizer',
        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (_summaries.isNotEmpty)
          IconButton(
            onPressed: _clearAllSummaries,
            icon: Icon(Icons.delete_sweep_rounded, size: 24.w),
            tooltip: 'Clear All',
          ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  value: _processingProgress,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Processing $_processingFileName...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: _processingProgress,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4.w),
          ),
          SizedBox(height: 8.h),
          Text(
            '${(_processingProgress * 100).round()}% Complete',
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(32.w),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.summarize_rounded,
                    size: 80.w,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  'No Files Summarized Yet',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Upload text files to get AI-powered summaries and key insights',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 32.h),
                _buildSupportedFormatsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportedFormatsCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Supported Formats',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: fs.FileSummarizationService.getSupportedExtensions()
                .map((ext) => _buildFormatChip(ext))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(String extension) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        extension.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSummariesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _summaries.length,
        itemBuilder: (context, index) {
          final summary = _summaries[index];
          return _buildSummaryCard(summary, index);
        },
      ),
    );
  }

  Widget _buildSummaryCard(fs.FileSummary summary, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.w),
          onTap: () => _showSummaryDetails(summary),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildFileTypeIcon(summary.fileType),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.fileName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${summary.wordCount} words • ${summary.estimatedReadingTime} min read',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildConfidenceIndicator(summary.confidenceScore),
                        SizedBox(width: 8.w),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteSummary(index);
                            } else if (value == 'share') {
                              _shareSummary(summary);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_rounded),
                                  SizedBox(width: 8),
                                  Text('Share'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          child: Icon(Icons.more_vert_rounded, size: 20.w),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  summary.summary,
                  style: TextStyle(fontSize: 14.sp, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (summary.keyPoints.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Text(
                    'Key Points:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  ...summary.keyPoints
                      .take(2)
                      .map(
                        (point) => Padding(
                          padding: EdgeInsets.only(left: 8.w, top: 2.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  point,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Processed ${_formatDate(summary.processedAt)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon(fs.FileType fileType) {
    IconData iconData;
    Color color;

    switch (fileType) {
      case fs.FileType.pdf:
        iconData = Icons.picture_as_pdf_rounded;
        color = Colors.red;
        break;
      case fs.FileType.word:
        iconData = Icons.description_rounded;
        color = Colors.blue;
        break;
      case fs.FileType.text:
        iconData = Icons.text_snippet_rounded;
        color = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Icon(iconData, size: 20.w, color: color),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color color;
    if (confidence >= 0.8) {
      color = Colors.green;
    } else if (confidence >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Text(
        '${(confidence * 100).round()}%',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _isProcessing ? null : _pickAndProcessFile,
      icon: Icon(
        _isProcessing ? Icons.hourglass_empty_rounded : Icons.add_rounded,
        size: 20.w,
      ),
      label: Text(
        _isProcessing ? 'Processing...' : 'Add File',
        style: TextStyle(fontSize: 16.sp),
      ),
      backgroundColor: _isProcessing
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primary,
      foregroundColor: _isProcessing
          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
          : Colors.white,
    );
  }

  Future<void> _pickAndProcessFile() async {
    try {
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: file_picker.FileType.custom,
        allowedExtensions: fs.FileSummarizationService.getSupportedExtensions()
            .map((ext) => ext.substring(1))
            .toList(),
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _processFile(file);
      }
    } catch (e) {
      _showErrorDialog('Error picking file', e.toString());
    }
  }

  Future<void> _processFile(File file) async {
    setState(() {
      _isProcessing = true;
      _processingFileName = file.path.split('/').last;
      _processingProgress = 0.0;
    });

    try {
      // Simulate processing steps
      setState(() => _processingProgress = 0.2);
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _processingProgress = 0.5);
      final summary = await fs.FileSummarizationService.processFile(file);

      setState(() => _processingProgress = 0.8);
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _summaries.insert(0, summary);
        _processingProgress = 1.0;
      });

      await _saveSummaries();
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isProcessing = false;
        _processingFileName = '';
        _processingProgress = 0.0;
      });

      _showSuccessSnackBar('File processed successfully!');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingFileName = '';
        _processingProgress = 0.0;
      });
      _showErrorDialog('Processing Error', e.toString());
    }
  }

  void _showSummaryDetails(fs.FileSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SummaryDetailsSheet(summary: summary),
    );
  }

  void _deleteSummary(int index) {
    setState(() {
      _summaries.removeAt(index);
    });
    _saveSummaries();
    _showSuccessSnackBar('Summary deleted');
  }

  void _clearAllSummaries() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Summaries'),
        content: const Text(
          'Are you sure you want to delete all summaries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _summaries.clear());
              _saveSummaries();
              Navigator.pop(context);
              _showSuccessSnackBar('All summaries cleared');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _shareSummary(fs.FileSummary summary) {
    // Implementation for sharing summary
    _showSuccessSnackBar('Share functionality coming soon!');
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _SummaryDetailsSheet extends StatelessWidget {
  final fs.FileSummary summary;

  const _SummaryDetailsSheet({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.h),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  summary.fileName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  '${summary.wordCount} words • ${summary.estimatedReadingTime} min read • ${(summary.confidenceScore * 100).round()}% confidence',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Summary', summary.summary),
                  if (summary.keyPoints.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _buildKeyPointsSection(summary.keyPoints),
                  ],
                  SizedBox(height: 24.h),
                  _buildSection('Original Text', summary.originalText),
                  SizedBox(height: 100.h), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.w),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Text(content, style: TextStyle(fontSize: 14.sp, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildKeyPointsSection(List<String> keyPoints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Points',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        ...keyPoints.map(
          (point) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 6.h),
                  width: 6.w,
                  height: 6.w,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(fontSize: 14.sp, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
