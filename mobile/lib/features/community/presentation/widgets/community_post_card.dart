import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/community_post_model.dart';
import '../providers/community_feed_provider.dart';
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
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          _buildAuthorRow(context, theme, isAuthor, ref),
          const SizedBox(height: 12),
          // Post content
          Text(
            post.content,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          // Post type badge for auto-posts
          if (post.isAutoPost) ...[
            const SizedBox(height: 8),
            _buildPostTypeBadge(theme),
          ],
          const SizedBox(height: 12),
          // Reaction bar
          ReactionBar(post: post),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context, ThemeData theme, bool isAuthor, WidgetRef ref) {
    final timeAgo = _formatTimeAgo(post.createdAt);

    return Row(
      children: [
        // Avatar
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
        // Name and time
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
        // Delete menu for author
        if (isAuthor)
          PopupMenuButton<String>(
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
                    Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPostTypeBadge(ThemeData theme) {
    String label;
    IconData icon;

    switch (post.postType) {
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
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(communityFeedProvider.notifier).deletePost(post.id);
      }
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}
