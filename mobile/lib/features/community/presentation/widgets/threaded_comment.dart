import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/comment_model.dart';

/// A comment tile with indented replies and "Reply" button.
class ThreadedCommentTile extends ConsumerWidget {
  final CommentModel comment;
  final VoidCallback onDelete;
  final ValueChanged<int> onReply;

  const ThreadedCommentTile({
    super.key,
    required this.comment,
    required this.onDelete,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authStateProvider).user?.id;
    final isAuthor = currentUserId == comment.authorId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        _CommentContent(
          comment: comment,
          isAuthor: isAuthor,
          onDelete: onDelete,
          onReply: () => onReply(comment.id),
          theme: theme,
        ),
        // Replies (indented)
        if (comment.hasReplies)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Column(
              children: comment.replies.map((reply) {
                final isReplyAuthor = currentUserId == reply.authorId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CommentContent(
                    comment: reply,
                    isAuthor: isReplyAuthor,
                    onDelete: onDelete,
                    onReply: () => onReply(comment.id),
                    theme: theme,
                    isReply: true,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _CommentContent extends StatelessWidget {
  final CommentModel comment;
  final bool isAuthor;
  final VoidCallback onDelete;
  final VoidCallback onReply;
  final ThemeData theme;
  final bool isReply;

  const _CommentContent({
    required this.comment,
    required this.isAuthor,
    required this.onDelete,
    required this.onReply,
    required this.theme,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${comment.authorDisplayName} said: ${comment.content}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 16,
            backgroundColor: theme.colorScheme.primary,
            backgroundImage: comment.authorProfileImage != null
                ? NetworkImage(comment.authorProfileImage!)
                : null,
            child: comment.authorProfileImage == null
                ? Text(
                    comment.authorInitials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isReply ? 9 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorDisplayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isReply ? 12 : 13,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: isReply ? 10 : 11,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: isReply ? 12 : 13,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (!isReply) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onReply,
                    child: Text(
                      'Reply',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isAuthor)
            IconButton(
              icon: Icon(Icons.close, size: 14, color: theme.disabledColor),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dateTime);
  }
}
