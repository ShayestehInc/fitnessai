import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/video_analysis_model.dart';
import '../providers/video_analysis_provider.dart';
import 'analysis_detail_screen.dart';
import 'video_upload_screen.dart';

/// Screen listing past video analyses with status indicators.
class AnalysisListScreen extends ConsumerWidget {
  const AnalysisListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analysesAsync = ref.watch(videoAnalysisListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Video Analysis'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const VideoUploadScreen(),
            ),
          );
        },
        child: const Icon(Icons.videocam),
      ),
      body: analysesAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(context, theme, error, ref),
        data: (analyses) {
          if (analyses.isEmpty) {
            return _buildEmptyState(context, theme);
          }
          return _buildAnalysesList(context, theme, analyses);
        },
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    Object error,
    WidgetRef ref,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load analyses',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(videoAnalysisListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No video analyses yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a workout video to get AI-powered form feedback.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VideoUploadScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.videocam),
              label: const Text('Upload Video'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysesList(
    BuildContext context,
    ThemeData theme,
    List<VideoAnalysisModel> analyses,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: analyses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final analysis = analyses[index];
        return _AnalysisListItem(
          analysis: analysis,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AnalysisDetailScreen(analysisId: analysis.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnalysisListItem extends StatelessWidget {
  final VideoAnalysisModel analysis;
  final VoidCallback onTap;

  const _AnalysisListItem({required this.analysis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String formattedDate;
    try {
      final dateTime = DateTime.parse(analysis.createdAt);
      formattedDate = DateFormat('MMM d, h:mm a').format(dateTime);
    } catch (_) {
      formattedDate = analysis.createdAt;
    }

    final statusColor = _statusColor(analysis.status);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.videocam_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.exerciseName ?? 'Video Analysis',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  analysis.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'uploaded':
        return const Color(0xFF6B7280);
      case 'processing':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF22C55E);
      case 'confirmed':
        return const Color(0xFF8B5CF6);
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
