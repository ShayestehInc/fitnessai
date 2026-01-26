import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/feature_request_model.dart';
import '../providers/feature_request_provider.dart';

class FeatureDetailScreen extends ConsumerStatefulWidget {
  final int featureId;

  const FeatureDetailScreen({
    super.key,
    required this.featureId,
  });

  @override
  ConsumerState<FeatureDetailScreen> createState() => _FeatureDetailScreenState();
}

class _FeatureDetailScreenState extends ConsumerState<FeatureDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featureAsync = ref.watch(featureRequestDetailProvider(widget.featureId));
    final commentsAsync = ref.watch(featureCommentsProvider(widget.featureId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Request'),
      ),
      body: featureAsync.when(
        data: (feature) {
          if (feature == null) {
            return const Center(child: Text('Feature request not found'));
          }
          return _buildContent(feature, commentsAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(FeatureRequestModel feature, AsyncValue<List<FeatureCommentModel>> commentsAsync) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Vote section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVoteColumn(feature),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status and category
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildStatusChip(feature.status, feature.statusDisplay),
                            _buildCategoryChip(feature.categoryDisplay),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          feature.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Submitted by
                        Text(
                          'Submitted by ${feature.submittedByName ?? feature.submittedByEmail ?? "Unknown"}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (feature.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(feature.createdAt!),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feature.description,
                  style: const TextStyle(height: 1.5),
                ),
              ),

              // Public response (if any)
              if (feature.publicResponse.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Official Response',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green[700], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'From the team',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(feature.publicResponse),
                    ],
                  ),
                ),
              ],

              // Target release (if any)
              if (feature.targetRelease.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Target: ${feature.targetRelease}',
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Comments section
              Row(
                children: [
                  Text(
                    'Comments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${feature.commentCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Comments list
              commentsAsync.when(
                data: (comments) {
                  if (comments.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: comments.map((comment) => _buildCommentCard(comment)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading comments: $e'),
              ),
            ],
          ),
        ),

        // Comment input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isSubmittingComment ? null : _submitComment,
                  icon: _isSubmittingComment
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoteColumn(FeatureRequestModel feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_upward,
              color: feature.hasUserUpvoted ? Colors.green : Colors.grey,
            ),
            onPressed: () => _vote(feature, 'up'),
          ),
          Text(
            '${feature.upvotes - feature.downvotes}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_downward,
              color: feature.hasUserDownvoted ? Colors.red : Colors.grey,
            ),
            onPressed: () => _vote(feature, 'down'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String display) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCommentCard(FeatureCommentModel comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: comment.isAdminResponse
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: comment.isAdminResponse
            ? Border.all(color: Colors.green.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (comment.isAdminResponse) ...[
                Icon(Icons.verified, color: Colors.green[700], size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                comment.userName ?? comment.userEmail ?? 'Anonymous',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: comment.isAdminResponse ? Colors.green[700] : null,
                ),
              ),
              if (comment.isAdminResponse) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Team',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (comment.createdAt != null)
                Text(
                  _formatDate(comment.createdAt!),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.content),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'planned':
        return Colors.purple;
      case 'in_development':
        return Colors.teal;
      case 'released':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _vote(FeatureRequestModel feature, String voteType) async {
    final actualVoteType = feature.userVote == voteType ? 'remove' : voteType;

    final result = await ref.read(featureRequestRepositoryProvider).vote(
          feature.id,
          actualVoteType,
        );

    if (result['success']) {
      ref.invalidate(featureRequestDetailProvider(widget.featureId));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to vote'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    final result = await ref.read(featureRequestRepositoryProvider).addComment(
          widget.featureId,
          content,
        );

    if (!mounted) return;

    setState(() => _isSubmittingComment = false);

    if (result['success']) {
      _commentController.clear();
      ref.invalidate(featureCommentsProvider(widget.featureId));
      ref.invalidate(featureRequestDetailProvider(widget.featureId));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to add comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
