import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/video_analysis_model.dart';
import '../providers/video_analysis_provider.dart';
import '../widgets/observation_card.dart';

/// Detail screen showing video analysis results.
class AnalysisDetailScreen extends ConsumerStatefulWidget {
  final int analysisId;

  const AnalysisDetailScreen({super.key, required this.analysisId});

  @override
  ConsumerState<AnalysisDetailScreen> createState() =>
      _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState
    extends ConsumerState<AnalysisDetailScreen> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisAsync =
        ref.watch(videoAnalysisDetailProvider(widget.analysisId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Analysis Results'),
      ),
      body: analysisAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(theme, error),
        data: (analysis) => _buildContent(theme, analysis),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
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
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(
                  videoAnalysisDetailProvider(widget.analysisId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, VideoAnalysisModel analysis) {
    String formattedDate;
    try {
      final dateTime = DateTime.parse(analysis.createdAt);
      formattedDate = DateFormat('MMMM d, yyyy h:mm a').format(dateTime);
    } catch (_) {
      formattedDate = analysis.createdAt;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(theme, analysis.status),
              Text(formattedDate, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 24),

          // Processing indicator
          if (analysis.isProcessing) ...[
            _buildProcessingBanner(theme),
            const SizedBox(height: 24),
          ],

          // Exercise info
          if (analysis.exerciseName != null) ...[
            _buildInfoCard(
              theme: theme,
              icon: Icons.fitness_center,
              label: 'Exercise Detected',
              value: analysis.exerciseName!,
            ),
            const SizedBox(height: 16),
          ],

          // Analysis data
          if (analysis.analysis != null &&
              analysis.analysis!.isNotEmpty) ...[
            Text('Analysis', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildAnalysisDetails(theme, analysis.analysis!),
            const SizedBox(height: 24),
          ],

          // Suggestions
          if (analysis.suggestions != null &&
              analysis.suggestions!.isNotEmpty) ...[
            Text('Suggestions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...analysis.suggestions!.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ObservationCard(
                  observation: entry.value,
                  index: entry.key,
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Failed state
          if (analysis.isFailed) ...[
            _buildFailedBanner(theme),
            const SizedBox(height: 24),
          ],

          // Confirm button
          if (analysis.isComplete &&
              analysis.status != 'confirmed') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _confirmAnalysis,
                child: _isConfirming
                    ? const AdaptiveSpinner.small()
                    : const Text('Confirm & Apply Suggestions'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    final Color color;
    switch (status) {
      case 'uploaded':
        color = const Color(0xFF6B7280);
      case 'processing':
        color = const Color(0xFF3B82F6);
      case 'completed':
        color = const Color(0xFF22C55E);
      case 'confirmed':
        color = const Color(0xFF8B5CF6);
      case 'failed':
        color = const Color(0xFFEF4444);
      default:
        color = const Color(0xFF6B7280);
    }

    final label = status.isNotEmpty
        ? '${status[0].toUpperCase()}${status.substring(1)}'
        : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProcessingBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: const AdaptiveSpinner.small(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your video is being analyzed by AI. This may take a moment.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedBanner(ThemeData theme) {
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
              'Analysis failed. Please try uploading again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDetails(
    ThemeData theme,
    Map<String, dynamic> analysisData,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: analysisData.entries.map((entry) {
          final value = entry.value;
          final displayValue =
              value is Map || value is List ? value.toString() : '$value';

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
        }).toList(),
      ),
    );
  }

  Future<void> _confirmAnalysis() async {
    setState(() => _isConfirming = true);

    final success = await ref
        .read(confirmSuggestionsProvider(widget.analysisId).notifier)
        .confirm();

    if (!mounted) return;

    if (success) {
      showAdaptiveToast(
        context,
        message: 'Suggestions confirmed!',
        type: ToastType.success,
      );
    } else {
      setState(() => _isConfirming = false);
      showAdaptiveToast(
        context,
        message: 'Failed to confirm. Please try again.',
        type: ToastType.error,
      );
    }
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
