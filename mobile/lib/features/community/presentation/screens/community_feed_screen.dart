import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/community_ws_service.dart';
import '../providers/announcement_provider.dart';
import '../providers/community_feed_provider.dart';
import '../widgets/announcement_card.dart';
import '../widgets/community_post_card.dart';
import '../widgets/compose_post_sheet.dart';

/// Main community tab screen combining announcements banner and feed.
class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityFeedProvider.notifier).loadFeed();
      ref.read(announcementProvider.notifier).loadAnnouncements();
      // Connect WebSocket for real-time updates
      ref.read(communityWsServiceProvider).connect();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final feedState = ref.watch(communityFeedProvider);
    final announcementState = ref.watch(announcementProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Community'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => context.push('/community/leaderboard'),
            tooltip: 'Leaderboard',
          ),
          if (announcementState.unreadCount > 0)
            _UnreadBadgeButton(
              count: announcementState.unreadCount,
              onTap: () => context.push('/community/announcements'),
            )
          else
            IconButton(
              icon: const Icon(Icons.campaign_outlined),
              onPressed: () => context.push('/community/announcements'),
              tooltip: 'Announcements',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(communityFeedProvider.notifier).loadFeed(),
            ref.read(announcementProvider.notifier).loadAnnouncements(),
          ]);
        },
        child: _buildBody(theme, feedState, announcementState),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showComposeSheet,
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'New post',
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    CommunityFeedState feedState,
    AnnouncementState announcementState,
  ) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return _buildLoadingSkeleton(theme);
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return _buildErrorState(theme, feedState.error!);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Pinned announcements banner
        if (announcementState.announcements
            .any((a) => a.isPinned)) ...[
          SliverToBoxAdapter(
            child: _buildPinnedAnnouncementBanner(
              theme,
              announcementState,
            ),
          ),
        ],

        // Feed posts
        if (feedState.posts.isEmpty)
          SliverFillRemaining(child: _buildEmptyState(theme))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= feedState.posts.length) {
                    return feedState.isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                Center(child: CircularProgressIndicator()),
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
    );
  }

  Widget _buildPinnedAnnouncementBanner(
    ThemeData theme,
    AnnouncementState announcementState,
  ) {
    final pinned = announcementState.announcements
        .where((a) => a.isPinned)
        .firstOrNull;
    if (pinned == null) return const SizedBox.shrink();
    return AnnouncementBanner(
      announcement: pinned,
      onTap: () => context.push('/community/announcements'),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something with your community!',
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

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () =>
                  ref.read(communityFeedProvider.notifier).loadFeed(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Semantics(
      label: 'Loading community feed',
      child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row skeleton
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.dividerColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, height: 12, color: theme.dividerColor),
                        const SizedBox(height: 4),
                        Container(width: 60, height: 10, color: theme.dividerColor),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Content skeleton (3 lines)
                Container(width: double.infinity, height: 12, color: theme.dividerColor),
                const SizedBox(height: 6),
                Container(width: double.infinity, height: 12, color: theme.dividerColor),
                const SizedBox(height: 6),
                Container(width: 200, height: 12, color: theme.dividerColor),
                const SizedBox(height: 12),
                // Reaction bar skeleton
                Row(
                  children: List.generate(3, (_) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 48,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
        );
      },
    ),
    );
  }

  void _showComposeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const ComposePostSheet(),
    );
  }
}

/// Badge button showing unread announcement count.
class _UnreadBadgeButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _UnreadBadgeButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.campaign_outlined),
          onPressed: onTap,
          tooltip: 'Announcements',
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
