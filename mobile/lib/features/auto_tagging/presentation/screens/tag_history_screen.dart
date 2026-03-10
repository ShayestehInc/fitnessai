import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auto_tag_provider.dart';
import '../widgets/tag_history_card.dart';

class TagHistoryScreen extends ConsumerStatefulWidget {
  final int exerciseId;
  final String exerciseName;

  const TagHistoryScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  ConsumerState<TagHistoryScreen> createState() => _TagHistoryScreenState();
}

class _TagHistoryScreenState extends ConsumerState<TagHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(tagHistoryProvider(widget.exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Tag History: ${widget.exerciseName}'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tagHistoryProvider(widget.exerciseId));
        },
        child: historyAsync.when(
          data: (entries) => _buildContent(theme, entries),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorState(theme, e.toString()),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, List entries) {
    if (entries.isEmpty) return _buildEmptyState(theme);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return TagHistoryCard(
          entry: entries[index],
          isFirst: index == 0,
          isLast: index == entries.length - 1,
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No tag history', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Tag changes will appear here as they are made.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
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
          Text('Failed to load history', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error, style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.invalidate(tagHistoryProvider(widget.exerciseId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
