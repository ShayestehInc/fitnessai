import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../progression/presentation/providers/progression_provider.dart';

/// Shows a banner when there are pending progression suggestions for
/// the user's active program. Navigates to the progression screen on tap.
class ProgressionAlertCard extends ConsumerWidget {
  final int programId;

  const ProgressionAlertCard({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync =
        ref.watch(progressionSuggestionsProvider(programId));

    return suggestionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return _ProgressionAlertContent(
          count: suggestions.length,
          programId: programId,
        );
      },
    );
  }
}

class _ProgressionAlertContent extends StatelessWidget {
  final int count;
  final int programId;

  const _ProgressionAlertContent({
    required this.count,
    required this.programId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.tertiaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/progression/$programId'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: theme.colorScheme.onTertiaryContainer,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count progression suggestion${count == 1 ? '' : 's'} available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
