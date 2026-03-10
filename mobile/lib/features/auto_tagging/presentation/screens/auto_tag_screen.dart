import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auto_tag_provider.dart';
import '../widgets/auto_tag_actions.dart';
import '../widgets/confidence_indicator.dart';
import '../widgets/status_badge.dart';
import '../widgets/tag_comparison_card.dart';
import '../../data/models/auto_tag_model.dart';
import 'tag_history_screen.dart';

class AutoTagScreen extends ConsumerStatefulWidget {
  final int exerciseId;
  final String exerciseName;

  const AutoTagScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  ConsumerState<AutoTagScreen> createState() => _AutoTagScreenState();
}

class _AutoTagScreenState extends ConsumerState<AutoTagScreen> {
  bool _isActionInProgress = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draftAsync = ref.watch(autoTagDraftProvider(widget.exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Auto-Tag: ${widget.exerciseName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Tag History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TagHistoryScreen(
                  exerciseId: widget.exerciseId,
                  exerciseName: widget.exerciseName,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(autoTagDraftProvider(widget.exerciseId));
        },
        child: draftAsync.when(
          data: (draft) => _buildContent(theme, draft),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorState(theme, e.toString()),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AutoTagDraftModel? draft) {
    if (draft == null) return _buildNoDraftState(theme);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusHeader(theme, draft),
        const SizedBox(height: 16),
        if (draft.confidence != null) ...[
          ConfidenceIndicator(draft: draft),
          const SizedBox(height: 16),
        ],
        TagComparisonCard(
          currentTags: draft.currentTags,
          proposedTags: draft.proposedTags,
        ),
        const SizedBox(height: 24),
        AutoTagActions(
          draft: draft,
          isActionInProgress: _isActionInProgress,
          onApply: _applyTags,
          onReject: _rejectTags,
          onRetry: _retryAutoTag,
        ),
      ],
    );
  }

  Widget _buildStatusHeader(ThemeData theme, AutoTagDraftModel draft) {
    return Row(
      children: [
        StatusBadge(status: draft.status, label: draft.statusDisplay),
        const Spacer(),
        Text(
          _formatDate(draft.createdAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDraftState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No Auto-Tag Draft', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Trigger auto-tagging to have AI analyze and propose tags.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isActionInProgress ? null : _triggerAutoTag,
              icon: _isActionInProgress
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: const Text('Trigger Auto-Tag'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64,
              color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load draft', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error, style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.invalidate(autoTagDraftProvider(widget.exerciseId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerAutoTag() async {
    setState(() => _isActionInProgress = true);
    final repo = ref.read(autoTagRepositoryProvider);
    final result = await repo.triggerAutoTag(widget.exerciseId);
    if (!mounted) return;
    _handleResult(result, 'Auto-tagging triggered');
  }

  Future<void> _applyTags() async {
    setState(() => _isActionInProgress = true);
    final repo = ref.read(autoTagRepositoryProvider);
    final result = await repo.applyTags(widget.exerciseId);
    if (!mounted) return;
    _handleResult(result, 'Tags applied successfully');
  }

  Future<void> _rejectTags() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Tags?'),
        content: const Text('Are you sure you want to reject the proposed tags?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isActionInProgress = true);
    final repo = ref.read(autoTagRepositoryProvider);
    final result = await repo.rejectTags(widget.exerciseId);
    if (!mounted) return;
    _handleResult(result, 'Tags rejected');
  }

  Future<void> _retryAutoTag() async {
    setState(() => _isActionInProgress = true);
    final repo = ref.read(autoTagRepositoryProvider);
    final result = await repo.retryAutoTag(widget.exerciseId);
    if (!mounted) return;
    _handleResult(result, 'Auto-tagging retried');
  }

  void _handleResult(Map<String, dynamic> result, String successMessage) {
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      ref.invalidate(autoTagDraftProvider(widget.exerciseId));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String? ?? 'Action failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    setState(() => _isActionInProgress = false);
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
