import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/progression_models.dart';
import '../providers/progression_provider.dart';
import '../widgets/progression_card.dart';

class ProgressionScreen extends ConsumerStatefulWidget {
  final int programId;

  const ProgressionScreen({
    super.key,
    required this.programId,
  });

  @override
  ConsumerState<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends ConsumerState<ProgressionScreen> {
  final Set<int> _loadingSuggestionIds = {};

  Future<void> _handleApprove(ProgressionSuggestionModel suggestion) async {
    setState(() => _loadingSuggestionIds.add(suggestion.id));
    try {
      final repository = ref.read(progressionRepositoryProvider);
      final result = await repository.approveSuggestion(suggestion.id);
      if (!mounted) return;

      if (result['success'] == true) {
        showAdaptiveToast(
          context,
          message: 'Suggestion approved for ${suggestion.exerciseName}',
          type: ToastType.success,
        );
        ref.invalidate(progressionSuggestionsProvider(widget.programId));
      } else {
        showAdaptiveToast(
          context,
          message: result['error'] as String? ?? 'Failed to approve',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSuggestionIds.remove(suggestion.id));
      }
    }
  }

  Future<void> _handleDismiss(ProgressionSuggestionModel suggestion) async {
    setState(() => _loadingSuggestionIds.add(suggestion.id));
    try {
      final repository = ref.read(progressionRepositoryProvider);
      final result = await repository.dismissSuggestion(suggestion.id);
      if (!mounted) return;

      if (result['success'] == true) {
        showAdaptiveToast(
          context,
          message: 'Suggestion dismissed',
          type: ToastType.info,
        );
        ref.invalidate(progressionSuggestionsProvider(widget.programId));
      } else {
        showAdaptiveToast(
          context,
          message: result['error'] as String? ?? 'Failed to dismiss',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSuggestionIds.remove(suggestion.id));
      }
    }
  }

  Future<void> _handleApply(ProgressionSuggestionModel suggestion) async {
    setState(() => _loadingSuggestionIds.add(suggestion.id));
    try {
      final repository = ref.read(progressionRepositoryProvider);
      final result = await repository.applySuggestion(suggestion.id);
      if (!mounted) return;

      if (result['success'] == true) {
        showAdaptiveToast(
          context,
          message: 'Progression applied to ${suggestion.exerciseName}',
          type: ToastType.success,
        );
        ref.invalidate(progressionSuggestionsProvider(widget.programId));
      } else {
        showAdaptiveToast(
          context,
          message: result['error'] as String? ?? 'Failed to apply',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSuggestionIds.remove(suggestion.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestionsAsync =
        ref.watch(progressionSuggestionsProvider(widget.programId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Progression'),
      ),
      body: suggestionsAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, stack) => _buildErrorState(theme, error),
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return _buildEmptyState(theme);
          }
          return _buildSuggestionsList(theme, suggestions);
        },
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
            const Icon(
              Icons.error_outline,
              color: AppTheme.destructive,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Suggestions',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(
                progressionSuggestionsProvider(widget.programId),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Suggestions Yet',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Keep training consistently and progression suggestions '
              'will appear here when your performance data shows '
              'readiness for advancement.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(
                progressionSuggestionsProvider(widget.programId),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Check Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(
    ThemeData theme,
    List<ProgressionSuggestionModel> suggestions,
  ) {
    final pending =
        suggestions.where((s) => s.status == 'pending').toList();
    final resolved =
        suggestions.where((s) => s.status != 'pending').toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(progressionSuggestionsProvider(widget.programId));
      },
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            Text(
              'Pending (${pending.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            ...pending.map(
              (s) => ProgressionCard(
                key: ValueKey(s.id),
                suggestion: s,
                isLoading: _loadingSuggestionIds.contains(s.id),
                onApprove: () => _handleApprove(s),
                onDismiss: () => _handleDismiss(s),
                onApply: () => _handleApply(s),
              ),
            ),
          ],
          if (resolved.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Resolved (${resolved.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            ...resolved.map(
              (s) => ProgressionCard(
                key: ValueKey(s.id),
                suggestion: s,
                isLoading: false,
                onApprove: () {},
                onDismiss: () {},
                onApply: () {},
              ),
            ),
          ],
        ],
      ),
    );
  }
}
