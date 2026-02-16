import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/community_post_model.dart';
import '../providers/community_feed_provider.dart';

/// Reaction bar displayed below each community post.
class ReactionBar extends ConsumerWidget {
  final CommunityPostModel post;

  const ReactionBar({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _ReactionButton(
          emoji: '\u{1F525}',
          label: 'fire',
          count: post.reactions.fire,
          isActive: post.userReactions.contains('fire'),
          theme: theme,
          onTap: () => _toggle(ref, 'fire'),
        ),
        const SizedBox(width: 8),
        _ReactionButton(
          emoji: '\u{1F44D}',
          label: 'thumbs_up',
          count: post.reactions.thumbsUp,
          isActive: post.userReactions.contains('thumbs_up'),
          theme: theme,
          onTap: () => _toggle(ref, 'thumbs_up'),
        ),
        const SizedBox(width: 8),
        _ReactionButton(
          emoji: '\u{2764}\u{FE0F}',
          label: 'heart',
          count: post.reactions.heart,
          isActive: post.userReactions.contains('heart'),
          theme: theme,
          onTap: () => _toggle(ref, 'heart'),
        ),
      ],
    );
  }

  void _toggle(WidgetRef ref, String reactionType) {
    ref.read(communityFeedProvider.notifier).toggleReaction(
          postId: post.id,
          reactionType: reactionType,
        );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final bool isActive;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.label,
    required this.count,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
