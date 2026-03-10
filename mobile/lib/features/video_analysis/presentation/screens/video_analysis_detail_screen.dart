import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/video_analysis_model.dart';
import '../providers/video_analysis_provider.dart';

/// Detail screen for a single video analysis showing results and suggestions.
class VideoAnalysisDetailScreen extends ConsumerStatefulWidget {
  final int analysisId;

  const VideoAnalysisDetailScreen({super.key, required this.analysisId});

  @override
  ConsumerState<VideoAnalysisDetailScreen> createState() =>
      _VideoAnalysisDetailScreenState();
}

class _VideoAnalysisDetailScreenState
    extends ConsumerState<VideoAnalysisDetailScreen> {
  Future<void> _confirmSuggestions() async {
    final confirmed = await ref
        .read(confirmSuggestionsProvider(widget.analysisId).notifier)
        .confirm();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          confirmed
              ? 'Suggestions confirmed successfully'
              : 'Failed to confirm suggestions',
        ),
        backgroundColor:
            confirmed ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisAsync =
        ref.watch(videoAnalysisDetailProvider(widget.analysisId));
    final confirmState =
        ref.watch(confirmSuggestionsProvider(widget.analysisId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Video Analysis'),
      ),
      body: analysisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(
            videoAnalysisDetailProvider(widget.analysisId),
          ),
        ),
        data: (analysis) => _DetailBody(
          analysis: analysis,
          confirmState: confirmState,
          onConfirm: _confirmSuggestions,
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final VideoAnalysisModel analysis;
  final AsyncValue<void> confirmState;
  final VoidCallback onConfirm;

  const _DetailBody({
    required this.analysis,
    required this.confirmState,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThumbnailSection(analysis: analysis),
          const SizedBox(height: 20),
          _HeaderRow(analysis: analysis),
          const SizedBox(height: 20),
          if (analysis.isProcessing) _buildProcessingState(theme),
          if (analysis.isFailed) _buildFailedState(theme),
          if (analysis.isComplete) ...[
            _AnalysisSection(analysis: analysis),
            const SizedBox(height: 20),
            _SuggestionsSection(analysis: analysis),
            const SizedBox(height: 24),
            _ConfirmButton(
              confirmState: confirmState,
              onConfirm: onConfirm,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Analyzing your video...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI is reviewing your form. This usually takes a few minutes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFailedState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Analysis failed. Please try uploading your video again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailSection extends StatelessWidget {
  final VideoAnalysisModel analysis;

  const _ThumbnailSection({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: analysis.thumbnailUrl != null
              ? Image.network(
                  analysis.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildPlaceholder(theme),
                )
              : _buildPlaceholder(theme),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.videocam_outlined,
        size: 48,
        color: theme.textTheme.bodySmall?.color,
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final VideoAnalysisModel analysis;

  const _HeaderRow({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String formattedDate;
    try {
      final dateTime = DateTime.parse(analysis.createdAt);
      formattedDate = DateFormat('MMMM d, yyyy h:mm a').format(dateTime);
    } catch (_) {
      formattedDate = analysis.createdAt;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          analysis.exerciseName ?? 'Video Analysis',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _StatusBadge(status: analysis.status, label: analysis.statusLabel),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formattedDate,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case 'completed':
        color = const Color(0xFF22C55E);
        break;
      case 'failed':
        color = const Color(0xFFEF4444);
        break;
      case 'processing':
      case 'uploaded':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AnalysisSection extends StatelessWidget {
  final VideoAnalysisModel analysis;

  const _AnalysisSection({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisData = analysis.analysis;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 18,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Text(
                'Form Breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (analysisData != null && analysisData.isNotEmpty)
            ...analysisData.entries.map((entry) {
              final displayValue = entry.value is Map || entry.value is List
                  ? entry.value.toString()
                  : '${entry.value}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        _formatKey(entry.key),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        displayValue,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Text(
              'No analysis data available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

class _SuggestionsSection extends StatelessWidget {
  final VideoAnalysisModel analysis;

  const _SuggestionsSection({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = analysis.suggestions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Text(
                'Suggestions',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (suggestions != null && suggestions.isNotEmpty)
            ...suggestions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}. ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Text(
              'No suggestions available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final AsyncValue<void> confirmState;
  final VoidCallback onConfirm;

  const _ConfirmButton({
    required this.confirmState,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: confirmState.isLoading ? null : onConfirm,
        icon: confirmState.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(
          confirmState.isLoading
              ? 'Confirming...'
              : 'Confirm Suggestions',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              'Failed to load analysis',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
