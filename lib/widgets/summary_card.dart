import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/file_summarization_service.dart' as fs;

class SummaryCard extends StatelessWidget {
  final fs.FileSummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isCompact;

  const SummaryCard({
    super.key,
    required this.summary,
    this.onTap,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.w : 16.w,
        vertical: isCompact ? 4.h : 8.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isCompact ? 12.w : 16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: isCompact ? 6.w : 10.w,
            offset: Offset(0, isCompact ? 1.h : 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isCompact ? 12.w : 16.w),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12.w : 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                if (!isCompact) ...[
                  SizedBox(height: 12.h),
                  _buildSummaryText(context),
                  SizedBox(height: 8.h),
                  _buildMetrics(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildFileTypeIcon(context),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.fileName,
                style: TextStyle(
                  fontSize: isCompact ? 14.sp : 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isCompact) ...[
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
            ],
          ),
        ),
        _buildConfidenceIndicator(context),
        if (onDelete != null) ...[
          SizedBox(width: 8.w),
          _buildActionButton(context),
        ],
      ],
    );
  }

  Widget _buildFileTypeIcon(BuildContext context) {
    IconData iconData;
    Color color;

    switch (summary.fileType) {
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
      padding: EdgeInsets.all(isCompact ? 6.w : 8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isCompact ? 6.w : 8.w),
      ),
      child: Icon(iconData, size: isCompact ? 16.w : 20.w, color: color),
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context) {
    Color color;
    if (summary.confidenceScore >= 0.8) {
      color = Colors.green;
    } else if (summary.confidenceScore >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6.w : 8.w,
        vertical: isCompact ? 2.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isCompact ? 10.w : 12.w),
      ),
      child: Text(
        '${(summary.confidenceScore * 100).round()}%',
        style: TextStyle(
          fontSize: isCompact ? 9.sp : 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete' && onDelete != null) {
          onDelete!();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 16),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
      child: Icon(
        Icons.more_vert_rounded,
        size: isCompact ? 16.w : 20.w,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildSummaryText(BuildContext context) {
    return Text(
      summary.summary,
      style: TextStyle(
        fontSize: 14.sp,
        height: 1.4,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetrics(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 12.w,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
        ),
        SizedBox(width: 4.w),
        Text(
          'Processed ${_formatDate(summary.processedAt)}',
          style: TextStyle(
            fontSize: 10.sp,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        if (summary.keyPoints.isNotEmpty) ...[
          Icon(
            Icons.list_alt_rounded,
            size: 12.w,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
          SizedBox(width: 4.w),
          Text(
            '${summary.keyPoints.length} key points',
            style: TextStyle(
              fontSize: 10.sp,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
