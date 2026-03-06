import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/community_post_model.dart';
import '../providers/community_feed_provider.dart';
import 'bookmark_button.dart';
import 'comments_sheet.dart';
import 'image_carousel.dart';
import 'reaction_bar.dart';

/// Card for a single community feed post.
class CommunityPostCard extends ConsumerWidget {
  final CommunityPostModel post;

  const CommunityPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authStateProvider).user?.id;
    final isAuthor = currentUserId == post.author.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: post.isAutoPost
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostAuthorRow(post: post, isAuthor: isAuthor),
          const SizedBox(height: 12),
          if (post.isPinned) ...[
            _PinIndicator(theme: theme),
            const SizedBox(height: 8),
          ],
          if (post.space != null) ...[
            _SpaceBadge(space: post.space!, theme: theme),
            const SizedBox(height: 8),
          ],
          if (post.isAutoPost) ...[
            _PostTypeBadge(postType: post.postType),
            const SizedBox(height: 8),
          ],
          _PostContent(post: post),
          if (post.hasImage) ...[
            const SizedBox(height: 10),
            ImageCarousel(images: post.images),
          ],
          const SizedBox(height: 12),
          _PostActions(post: post),
        ],
      ),
    );
  }
}

/// Pin indicator badge.
class _PinIndicator extends StatelessWidget {
  final ThemeData theme;

  const _PinIndicator({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          'Pinned',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Space badge showing which space the post belongs to.
class _SpaceBadge extends StatelessWidget {
  final PostSpaceInfo space;
  final ThemeData theme;

  const _SpaceBadge({required this.space, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${space.emoji} ${space.name}',
        style: TextStyle(
          fontSize: 11,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

/// Author row with avatar, name, time, and delete menu.
class _PostAuthorRow extends ConsumerWidget {
  final CommunityPostModel post;
  final bool isAuthor;

  const _PostAuthorRow({required this.post, required this.isAuthor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(post.createdAt);

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primary,
          backgroundImage: post.author.profileImage != null
              ? NetworkImage(post.author.profileImage!)
              : null,
          child: post.author.profileImage == null
              ? Text(
                  post.author.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author.displayName,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                timeAgo,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        BookmarkButton(postId: post.id, isBookmarked: post.isBookmarked),
        if (isAuthor)
          Theme.of(context).platform == TargetPlatform.iOS
              ? IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: theme.textTheme.bodySmall?.color,
                    size: 20,
                  ),
                  onPressed: () => showAdaptiveActionSheet(
                    context: context,
                    actions: [
                      AdaptiveAction(
                        label: 'Delete',
                        isDestructive: true,
                        onPressed: () => _confirmDelete(context, ref),
                      ),
                    ],
                  ),
                )
              : PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    color: theme.textTheme.bodySmall?.color,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Delete this post? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final success =
            await ref.read(communityFeedProvider.notifier).deletePost(post.id);
        if (!context.mounted) return;
        showAdaptiveToast(
          context,
          message: success ? 'Post deleted' : 'Failed to delete post',
          type: success ? ToastType.success : ToastType.error,
        );
      }
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}

/// Renders post content as plain text or markdown.
class _PostContent extends StatelessWidget {
  final CommunityPostModel post;

  const _PostContent({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (post.isMarkdown) {
      return MarkdownBody(
        data: post.content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 14,
            height: 1.4,
          ),
          strong: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          em: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
          code: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 13,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
          blockquoteDecoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
          ),
        ),
      );
    }

    return Text(
      post.content,
      style: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }
}

/// Post type badge for auto-generated posts.
class _PostTypeBadge extends StatelessWidget {
  final String postType;

  const _PostTypeBadge({required this.postType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    IconData icon;

    switch (postType) {
      case 'workout_completed':
        label = 'Workout';
        icon = Icons.fitness_center;
      case 'achievement_earned':
        label = 'Achievement';
        icon = Icons.emoji_events;
      case 'weight_milestone':
        label = 'Milestone';
        icon = Icons.trending_up;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reaction bar and comment button row.
class _PostActions extends StatelessWidget {
  final CommunityPostModel post;

  const _PostActions({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: ReactionBar(post: post)),
        const SizedBox(width: 8),
        _CommentButton(
          count: post.commentCount,
          onTap: () => _openComments(context),
          theme: theme,
        ),
      ],
    );
  }

  void _openComments(BuildContext context) {
    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentsSheet(postId: post.id),
    );
  }
}

/// Comment count button.
class _CommentButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final ThemeData theme;

  const _CommentButton({
    required this.count,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count comments. Tap to view.',
      button: true,
      child: AdaptiveTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 14, color: theme.textTheme.bodySmall?.color),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
