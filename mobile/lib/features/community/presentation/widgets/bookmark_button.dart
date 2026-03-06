import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_feed_provider.dart';

/// Bookmark toggle icon button for a post.
class BookmarkButton extends ConsumerWidget {
  final int postId;
  final bool isBookmarked;

  const BookmarkButton({
    super.key,
    required this.postId,
    required this.isBookmarked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Semantics(
      label: isBookmarked ? 'Remove bookmark' : 'Bookmark this post',
      button: true,
      child: IconButton(
        icon: Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          size: 20,
          color: isBookmarked
              ? theme.colorScheme.primary
              : theme.textTheme.bodySmall?.color,
        ),
        onPressed: () {
          ref.read(communityFeedProvider.notifier).toggleBookmark(postId);
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}
