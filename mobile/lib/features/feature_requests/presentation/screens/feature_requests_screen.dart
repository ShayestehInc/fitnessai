import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/feature_request_model.dart';
import '../providers/feature_request_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

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
        title: Text(context.l10n.settingsFeatureRequests),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          if (Theme.of(context).platform == TargetPlatform.iOS)
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(context.l10n.featureReqRequest),
              onPressed: () => context.push('/feature-requests/submit'),
            ),
        ],
      ),
      body: AdaptiveRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featureRequestsProvider(params));
        },
        child: featuresAsync.when(
          data: (features) {
            if (features.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              physics: adaptiveAlwaysScrollablePhysics(context),
              padding: const EdgeInsets.all(16),
              itemCount: features.length,
              itemBuilder: (context, index) {
                return _buildFeatureCard(features[index]);
              },
            );
          },
          loading: () => const Center(child: AdaptiveSpinner()),
          error: (e, _) => Center(child: Text(context.l10n.featureReqErrore)),
        ),
      ),
      floatingActionButton: Theme.of(context).platform == TargetPlatform.iOS
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/feature-requests/submit'),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.featureReqRequestFeature),
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
            label: Text(context.l10n.featureReqRequestFeature),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(FeatureRequestModel feature) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: AdaptiveTappable(
        onTap: () => context.push('/feature-requests/${feature.id}'),
        borderRadius: BorderRadius.circular(12),
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
        showAdaptiveToast(context, message: result['error'] ?? 'Failed to vote', type: ToastType.error);
      }
    }
  }

  void _showFilterDialog() {
    showAdaptiveBottomSheet(
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
            Text(context.l10n.featureReqSortBy, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.l10n.featureReqMostVotes),
                  selected: _sortBy == 'votes',
                  onSelected: (_) => setState(() => _sortBy = 'votes'),
                ),
                ChoiceChip(
                  label: Text(context.l10n.featureReqRecent),
                  selected: _sortBy == 'recent',
                  onSelected: (_) => setState(() => _sortBy = 'recent'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status filter
            Text(context.l10n.featureReqStatus, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.l10n.commonAll),
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
                child: Text(context.l10n.featureReqApply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
