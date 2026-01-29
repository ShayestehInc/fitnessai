import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/feature_request_model.dart';
import '../providers/feature_request_provider.dart';

class FeatureRequestsScreen extends ConsumerStatefulWidget {
  const FeatureRequestsScreen({super.key});

  @override
  ConsumerState<FeatureRequestsScreen> createState() => _FeatureRequestsScreenState();
}

class _FeatureRequestsScreenState extends ConsumerState<FeatureRequestsScreen> {
  String? _selectedCategory;
  String? _selectedStatus;
  String _sortBy = 'votes';

  @override
  Widget build(BuildContext context) {
    final params = {
      'category': _selectedCategory,
      'status': _selectedStatus,
      'sort': _sortBy,
    };
    final featuresAsync = ref.watch(featureRequestsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featureRequestsProvider(params));
        },
        child: featuresAsync.when(
          data: (features) {
            if (features.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: features.length,
              itemBuilder: (context, index) {
                return _buildFeatureCard(features[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/feature-requests/submit'),
        icon: const Icon(Icons.add),
        label: const Text('Request Feature'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No feature requests yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to suggest a feature!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/feature-requests/submit'),
            icon: const Icon(Icons.add),
            label: const Text('Request Feature'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(FeatureRequestModel feature) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/feature-requests/${feature.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vote column
                  Column(
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
                          fontSize: 16,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status chip
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(feature.status).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                feature.statusDisplay,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(feature.status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                feature.categoryDisplay,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          feature.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Description preview
                        Text(
                          feature.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Footer
                        Row(
                          children: [
                            Icon(Icons.comment, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${feature.commentCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'by ${feature.submittedByName ?? feature.submittedByEmail ?? "Unknown"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  void _vote(FeatureRequestModel feature, String voteType) async {
    // If already voted same way, remove vote
    final actualVoteType = feature.userVote == voteType ? 'remove' : voteType;

    final result = await ref.read(featureRequestRepositoryProvider).vote(
          feature.id,
          actualVoteType,
        );

    if (result['success']) {
      final params = {
        'category': _selectedCategory,
        'status': _selectedStatus,
        'sort': _sortBy,
      };
      ref.invalidate(featureRequestsProvider(params));
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Sort',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Sort by
            Text('Sort by', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Most Votes'),
                  selected: _sortBy == 'votes',
                  onSelected: (_) => setState(() => _sortBy = 'votes'),
                ),
                ChoiceChip(
                  label: const Text('Recent'),
                  selected: _sortBy == 'recent',
                  onSelected: (_) => setState(() => _sortBy = 'recent'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status filter
            Text('Status', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedStatus == null,
                  onSelected: (_) => setState(() => _selectedStatus = null),
                ),
                ...FeatureStatus.values.map(
                  (status) => ChoiceChip(
                    label: Text(status.display),
                    selected: _selectedStatus == status.value,
                    onSelected: (_) => setState(() => _selectedStatus = status.value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
