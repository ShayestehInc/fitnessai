import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/progression_profile_model.dart';
import '../providers/progression_profile_provider.dart';
import '../widgets/suggestion_card.dart';

class ProgressionSuggestionsScreen extends ConsumerStatefulWidget {
  const ProgressionSuggestionsScreen({super.key});

  @override
  ConsumerState<ProgressionSuggestionsScreen> createState() =>
      _ProgressionSuggestionsScreenState();
}

class _ProgressionSuggestionsScreenState
    extends ConsumerState<ProgressionSuggestionsScreen> {
  final Set<int> _actionInProgress = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(progressionSuggestionsListProvider.notifier).loadSuggestions();
    });
  }

  Future<void> _handleApprove(ProgressionPlanSuggestionModel suggestion) async {
    setState(() => _actionInProgress.add(suggestion.id));
    try {
      final success = await ref
          .read(progressionSuggestionsListProvider.notifier)
          .approveSuggestion(suggestion.id);
      if (!mounted) return;
      if (success) {
        showAdaptiveToast(
          context,
          message: 'Approved: ${suggestion.exerciseName}',
          type: ToastType.success,
        );
      } else {
        showAdaptiveToast(
          context,
          message: 'Failed to approve suggestion',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionInProgress.remove(suggestion.id));
      }
    }
  }

  Future<void> _handleDismiss(
      ProgressionPlanSuggestionModel suggestion) async {
    setState(() => _actionInProgress.add(suggestion.id));
    try {
      final success = await ref
          .read(progressionSuggestionsListProvider.notifier)
          .dismissSuggestion(suggestion.id);
      if (!mounted) return;
      if (success) {
        showAdaptiveToast(
          context,
          message: 'Suggestion dismissed',
          type: ToastType.info,
        );
      } else {
        showAdaptiveToast(
          context,
          message: 'Failed to dismiss suggestion',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionInProgress.remove(suggestion.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestionsState = ref.watch(progressionSuggestionsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progression Suggestions')),
      body: _buildBody(theme, suggestionsState),
    );
  }

  Widget _buildBody(ThemeData theme, ProgressionSuggestionsListState state) {
    if (state.isLoading) {
      return const Center(child: AdaptiveSpinner());
    }
    if (state.error != null) {
      return _buildError(theme, state.error!);
    }
    if (state.suggestions.isEmpty) {
      return _buildEmpty(theme);
    }
    return _buildList(theme, state.suggestions);
  }

  Widget _buildError(ThemeData theme, String error) {
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
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(progressionSuggestionsListProvider.notifier)
                  .loadSuggestions(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
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
                Icons.auto_graph,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Pending Suggestions',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'You have no pending progression suggestions. '
              'Keep training consistently and new suggestions '
              'will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(progressionSuggestionsListProvider.notifier)
                  .loadSuggestions(),
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

  Widget _buildList(
    ThemeData theme,
    List<ProgressionPlanSuggestionModel> suggestions,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(progressionSuggestionsListProvider.notifier)
            .loadSuggestions();
      },
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return SuggestionCard(
            key: ValueKey(suggestion.id),
            suggestion: suggestion,
            isLoading: _actionInProgress.contains(suggestion.id),
            onApprove: () => _handleApprove(suggestion),
            onDismiss: () => _handleDismiss(suggestion),
          );
        },
      ),
    );
  }
}
