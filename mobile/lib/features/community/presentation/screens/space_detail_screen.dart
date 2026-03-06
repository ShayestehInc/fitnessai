import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/space_model.dart';
import '../providers/community_feed_provider.dart';
import '../providers/space_provider.dart';
import '../widgets/community_post_card.dart';
import '../widgets/compose_post_sheet.dart';
import '../widgets/sort_toggle.dart';

/// Detail screen for a single space — shows header, members count, feed.
class SpaceDetailScreen extends ConsumerStatefulWidget {
  final int spaceId;

  const SpaceDetailScreen({super.key, required this.spaceId});

  @override
  ConsumerState<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends ConsumerState<SpaceDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set the space filter and reload feed
      ref.read(currentSpaceIdProvider.notifier).state = widget.spaceId;
      ref.read(communityFeedProvider.notifier).loadFeed();
      ref.read(spaceMembersProvider(widget.spaceId).notifier).loadMembers();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Reset space filter when leaving
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
      // Only reset if still pointing to this space
      // (user might have navigated to another space)
    });
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(communityFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacesState = ref.watch(spacesProvider);
    final feedState = ref.watch(communityFeedProvider);
    final membersState = ref.watch(spaceMembersProvider(widget.spaceId));

    final space = spacesState.spaces
        .where((s) => s.id == widget.spaceId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(space?.name ?? 'Space'),
        elevation: 0,
      ),
      body: AdaptiveRefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(communityFeedProvider.notifier).loadFeed(),
            ref.read(spaceMembersProvider(widget.spaceId).notifier)
                .loadMembers(),
          ]);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: adaptiveAlwaysScrollablePhysics(context),
          slivers: [
            // Space header
            if (space != null)
              SliverToBoxAdapter(
                child: _SpaceHeader(
                  space: space,
                  memberCount: membersState.members.isNotEmpty
                      ? membersState.members.length
                      : space.memberCount,
                  onJoin: () => _joinSpace(space),
                  onLeave: () => _leaveSpace(space),
                ),
              ),

            // Sort toggle
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [const SortToggle()],
                ),
              ),
            ),

            // Feed
            if (feedState.isLoading && feedState.posts.isEmpty)
              const SliverFillRemaining(
                child: Center(child: AdaptiveSpinner()),
              )
            else if (feedState.posts.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(theme))
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= feedState.posts.length) {
                        return feedState.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: AdaptiveSpinner()),
                              )
                            : const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CommunityPostCard(
                          post: feedState.posts[index],
                        ),
                      );
                    },
                    childCount: feedState.posts.length +
                        (feedState.hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: space != null && space.isMember
          ? FloatingActionButton(
              onPressed: () => _showComposeSheet(),
              backgroundColor: theme.colorScheme.primary,
              tooltip: 'New post',
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined,
                size: 64, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              'No posts in this space yet',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinSpace(SpaceModel space) async {
    final success = await ref.read(spacesProvider.notifier).joinSpace(space.id);
    if (!mounted) return;
    showAdaptiveToast(
      context,
      message: success ? 'Joined ${space.name}' : 'Failed to join',
      type: success ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _leaveSpace(SpaceModel space) async {
    final success =
        await ref.read(spacesProvider.notifier).leaveSpace(space.id);
    if (!mounted) return;
    showAdaptiveToast(
      context,
      message: success ? 'Left ${space.name}' : 'Failed to leave',
      type: success ? ToastType.success : ToastType.error,
    );
  }

  void _showComposeSheet() {
    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ComposePostSheet(initialSpaceId: widget.spaceId),
    );
  }
}

/// Header showing space info, cover, and join/leave button.
class _SpaceHeader extends StatelessWidget {
  final SpaceModel space;
  final int memberCount;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _SpaceHeader({
    required this.space,
    required this.memberCount,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  space.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount member${memberCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                        ),
                        if (space.isPrivate) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.lock_outline,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color),
                          const SizedBox(width: 2),
                          Text(
                            'Private',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (space.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              space.description,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: space.isMember
                ? OutlinedButton(
                    onPressed: onLeave,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Leave Space'),
                  )
                : ElevatedButton(
                    onPressed: onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Join Space'),
                  ),
          ),
        ],
      ),
    );
  }
}
