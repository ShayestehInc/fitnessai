import 'package:flutter/material.dart';
import '../../data/models/auto_tag_model.dart';

class AutoTagActions extends StatelessWidget {
  final AutoTagDraftModel draft;
  final bool isActionInProgress;
  final VoidCallback onApply;
  final VoidCallback onReject;
  final VoidCallback onRetry;

  const AutoTagActions({
    super.key,
    required this.draft,
    required this.isActionInProgress,
    required this.onApply,
    required this.onReject,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (draft.isProcessing) {
      return _buildProcessingState(theme);
    }
    if (draft.isFailed) {
      return _buildFailedActions(theme);
    }
    if (draft.isApplied || draft.isRejected) {
      return _buildCompletedState(theme);
    }
    return _buildPendingActions(theme);
  }

  Widget _buildPendingActions(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isActionInProgress ? null : onApply,
            icon: isActionInProgress
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Apply Tags'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isActionInProgress ? null : onReject,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing...', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'AI is analyzing the exercise and generating tags.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedActions(ThemeData theme) {
    return Column(
      children: [
        Card(
          color: theme.colorScheme.error.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Auto-tagging failed. You can retry the process.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isActionInProgress ? null : onRetry,
            icon: isActionInProgress
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Retry Auto-Tag'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedState(ThemeData theme) {
    return Card(
      color: draft.isApplied
          ? Colors.green.withValues(alpha: 0.08)
          : theme.colorScheme.onSurface.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              draft.isApplied ? Icons.check_circle : Icons.cancel,
              color: draft.isApplied ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                draft.isApplied
                    ? 'Tags have been applied to this exercise.'
                    : 'This draft was rejected.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
