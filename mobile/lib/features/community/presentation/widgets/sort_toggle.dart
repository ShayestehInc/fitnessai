import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_feed_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Toggle chip for switching between Latest and Popular feed sort.
class SortToggle extends ConsumerWidget {
  const SortToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentSort = ref.watch(feedSortProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SortChip(
          label: context.l10n.communityLatest,
          isSelected: currentSort == FeedSort.latest,
          onTap: () {
            ref.read(feedSortProvider.notifier).state = FeedSort.latest;
            ref.read(communityFeedProvider.notifier).loadFeed();
          },
          theme: theme,
        ),
        const SizedBox(width: 8),
        _SortChip(
          label: context.l10n.communityPopular,
          isSelected: currentSort == FeedSort.popular,
          onTap: () {
            ref.read(feedSortProvider.notifier).state = FeedSort.popular;
            ref.read(communityFeedProvider.notifier).loadFeed();
          },
          theme: theme,
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyMedium?.color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
