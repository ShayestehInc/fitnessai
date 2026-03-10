import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/feedback_models.dart';
import '../providers/feedback_provider.dart';

/// Screen listing past session feedback entries.
class FeedbackHistoryScreen extends ConsumerWidget {
  const FeedbackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final feedbackAsync = ref.watch(feedbackListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Feedback History'),
      ),
      body: feedbackAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(theme, error, ref),
        data: (feedbackList) {
          if (feedbackList.isEmpty) {
            return _buildEmptyState(theme);
          }
          return _buildFeedbackList(theme, feedbackList, ref);
        },
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error, WidgetRef ref) {
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
              'Failed to load feedback',
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
              onPressed: () => ref.invalidate(feedbackListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.feedback_outlined,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No feedback yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your session feedback will appear here after you complete workouts.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList(
    ThemeData theme,
    List<SessionFeedbackModel> feedbackList,
    WidgetRef ref,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(feedbackListProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: feedbackList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _FeedbackCard(feedback: feedbackList[index]);
        },
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final SessionFeedbackModel feedback;

  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overallRating = feedback.ratings['overall'] ?? 0;

    String formattedDate;
    try {
      final dateTime = DateTime.parse(feedback.createdAt);
      formattedDate = DateFormat('MMM d, yyyy h:mm a').format(dateTime);
    } catch (_) {
      formattedDate = feedback.createdAt;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CompletionBadge(state: feedback.completionState),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < overallRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 20,
                    color: i < overallRating
                        ? const Color(0xFFF59E0B)
                        : theme.dividerColor,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  'Overall: $overallRating/5',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (feedback.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                feedback.notes,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (feedback.painEvents.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${feedback.painEvents.length} pain event(s)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  final String state;

  const _CompletionBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;

    switch (state) {
      case 'completed':
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.15);
        textColor = const Color(0xFF22C55E);
      case 'partial':
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        textColor = const Color(0xFFF59E0B);
      case 'skipped':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        textColor = const Color(0xFFEF4444);
      default:
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey;
    }

    final label = state.isNotEmpty
        ? '${state[0].toUpperCase()}${state.substring(1)}'
        : state;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
