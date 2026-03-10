import 'package:flutter/material.dart';

import '../../data/models/video_analysis_model.dart';

/// Card widget displaying a video analysis summary in a list.
class VideoAnalysisCard extends StatelessWidget {
  final VideoAnalysisModel analysis;
  final VoidCallback onTap;

  const VideoAnalysisCard({
    super.key,
    required this.analysis,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            _buildThumbnail(theme),
            Expanded(child: _buildInfo(theme)),
            _buildStatusIndicator(theme),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      color: theme.colorScheme.surfaceContainerHighest,
      child: analysis.thumbnailUrl != null
          ? Image.network(
              analysis.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderIcon(theme),
            )
          : _buildPlaceholderIcon(theme),
    );
  }

  Widget _buildPlaceholderIcon(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.videocam_outlined,
        size: 32,
        color: theme.textTheme.bodySmall?.color,
      ),
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            analysis.exerciseName ?? 'Video Analysis',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            analysis.statusLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _statusColor(theme),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(analysis.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    if (analysis.isProcessing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final IconData icon;
    final Color color;

    if (analysis.isComplete) {
      icon = Icons.check_circle;
      color = const Color(0xFF22C55E);
    } else if (analysis.isFailed) {
      icon = Icons.error;
      color = const Color(0xFFEF4444);
    } else {
      icon = Icons.pending;
      color = theme.textTheme.bodySmall?.color ?? Colors.grey;
    }

    return Icon(icon, size: 20, color: color);
  }

  Color _statusColor(ThemeData theme) {
    if (analysis.isComplete) return const Color(0xFF22C55E);
    if (analysis.isFailed) return const Color(0xFFEF4444);
    if (analysis.isProcessing) return const Color(0xFFF59E0B);
    return theme.textTheme.bodySmall?.color ?? Colors.grey;
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
