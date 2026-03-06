import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/community_feed_repository.dart';
import '../providers/community_feed_provider.dart';
import 'threaded_comment.dart';

/// Bottom sheet that shows threaded comments for a post.
class CommentsSheet extends ConsumerStatefulWidget {
  final int postId;

  const CommentsSheet({super.key, required this.postId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  int? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final repo = CommunityFeedRepository(apiClient);
      final comments = await repo.getComments(postId: widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load comments';
      });
    }
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final repo = CommunityFeedRepository(apiClient);
      final comment = await repo.createComment(
        postId: widget.postId,
        content: content,
        parentCommentId: _replyingToId,
      );
      if (!mounted) return;

      if (_replyingToId != null) {
        // Add as reply to parent
        setState(() {
          _comments = _comments.map((c) {
            if (c.id == _replyingToId) {
              return CommentModel(
                id: c.id,
                postId: c.postId,
                parentCommentId: c.parentCommentId,
                authorId: c.authorId,
                authorFirstName: c.authorFirstName,
                authorLastName: c.authorLastName,
                authorProfileImage: c.authorProfileImage,
                content: c.content,
                createdAt: c.createdAt,
                replies: [...c.replies, comment],
              );
            }
            return c;
          }).toList();
          _isSubmitting = false;
          _replyingToId = null;
          _replyingToName = null;
        });
      } else {
        setState(() {
          _comments.add(comment);
          _isSubmitting = false;
        });
      }

      _controller.clear();
      ref.read(communityFeedProvider.notifier).onNewComment(widget.postId);

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAdaptiveToast(context,
          message: 'Failed to post comment', type: ToastType.error);
    }
  }

  int get _totalComments {
    int count = _comments.length;
    for (final c in _comments) {
      count += c.replies.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            _buildHeader(theme),
            const Divider(height: 1),
            Expanded(child: _buildBody(theme)),
            if (_replyingToId != null) _buildReplyBanner(theme),
            const Divider(height: 1),
            _buildInput(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Comments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($_totalComments)',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: AdaptiveSpinner());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loadComments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Text(
          'No comments yet. Be the first!',
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => ThreadedCommentTile(
        comment: _comments[index],
        onDelete: () => _deleteComment(index),
        onReply: (parentId) {
          final parent = _comments[index];
          setState(() {
            _replyingToId = parentId;
            _replyingToName = parent.authorDisplayName;
          });
        },
      ),
    );
  }

  Widget _buildReplyBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Replying to $_replyingToName',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _replyingToId = null;
              _replyingToName = null;
            }),
            child: Icon(Icons.close, size: 16, color: theme.disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: 500,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: _replyingToId != null
                      ? 'Reply...'
                      : 'Write a comment...',
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed:
                  _controller.text.trim().isNotEmpty && !_isSubmitting
                      ? _submitComment
                      : null,
              icon: _isSubmitting
                  ? AdaptiveSpinner.small()
                  : Icon(
                      Icons.send,
                      color: _controller.text.trim().isNotEmpty
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteComment(int index) async {
    final comment = _comments[index];
    final currentUserId = ref.read(authStateProvider).user?.id;
    if (comment.authorId != currentUserId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Delete this comment?'),
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
    );

    if (confirmed != true) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      final repo = CommunityFeedRepository(apiClient);
      await repo.deleteComment(
        postId: widget.postId,
        commentId: comment.id,
      );
      if (!mounted) return;
      setState(() => _comments.removeAt(index));
    } catch (_) {
      if (!mounted) return;
      showAdaptiveToast(context,
          message: 'Failed to delete comment', type: ToastType.error);
    }
  }
}
