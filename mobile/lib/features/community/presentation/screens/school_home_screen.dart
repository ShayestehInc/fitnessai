import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/services/community_ws_service.dart';
import '../providers/announcement_provider.dart';
import '../providers/community_feed_provider.dart';
import '../providers/space_provider.dart';
import '../widgets/announcement_card.dart';
import '../widgets/community_post_card.dart';
import '../widgets/compose_post_sheet.dart';
import '../widgets/sort_toggle.dart';
import '../widgets/space_chip.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Main "School" tab screen — replaces the old community feed.
/// Shows horizontal space chips, sort toggle, and the feed.
class SchoolHomeScreen extends ConsumerStatefulWidget {
  const SchoolHomeScreen({super.key});

  @override
  ConsumerState<SchoolHomeScreen> createState() => _SchoolHomeScreenState();
}

class _SchoolHomeScreenState extends ConsumerState<SchoolHomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityFeedProvider.notifier).loadFeed();
      ref.read(announcementProvider.notifier).loadAnnouncements();
      ref.read(spacesProvider.notifier).loadSpaces();
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
    final spacesState = ref.watch(spacesProvider);
    final selectedSpaceId = ref.watch(currentSpaceIdProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.navCommunity),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_outlined),
            onPressed: () => context.push('/community/events'),
            tooltip: context.l10n.communityEvents,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => context.push('/community/saved'),
            tooltip: context.l10n.communitySaved,
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => context.push('/community/leaderboard'),
            tooltip: context.l10n.communityLeaderboard,
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
              tooltip: context.l10n.trainerAnnouncements,
            ),
          if (Theme.of(context).platform == TargetPlatform.iOS)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showComposeSheet(selectedSpaceId),
              tooltip: context.l10n.communityNewPost,
            ),
        ],
      ),
      body: AdaptiveRefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(communityFeedProvider.notifier).loadFeed(),
            ref.read(announcementProvider.notifier).loadAnnouncements(),
            ref.read(spacesProvider.notifier).loadSpaces(),
          ]);
        },
        child: _buildBody(
          theme, feedState, announcementState, spacesState, selectedSpaceId,
        ),
      ),
      floatingActionButton: Theme.of(context).platform == TargetPlatform.iOS
          ? null
          : FloatingActionButton(
              onPressed: () => _showComposeSheet(selectedSpaceId),
              backgroundColor: theme.colorScheme.primary,
              tooltip: context.l10n.communityNewPost,
              child: const Icon(Icons.edit),
            ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    CommunityFeedState feedState,
    AnnouncementState announcementState,
    SpacesState spacesState,
    int? selectedSpaceId,
  ) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return _buildLoadingSkeleton(theme);
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return _buildErrorState(theme, feedState.error!);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: adaptiveAlwaysScrollablePhysics(context),
      slivers: [
        // Pinned announcements banner
        if (announcementState.announcements.any((a) => a.isPinned))
          SliverToBoxAdapter(
            child: _buildPinnedAnnouncementBanner(theme, announcementState),
          ),

        // Space chips
        if (spacesState.spaces.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SpaceChipBar(
                spaces: spacesState.spaces,
                selectedSpaceId: selectedSpaceId,
                onSelected: (spaceId) {
                  ref.read(currentSpaceIdProvider.notifier).state = spaceId;
                  ref.read(communityFeedProvider.notifier).loadFeed();
                },
              ),
            ),
          ),

        // Sort toggle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [const SortToggle()],
            ),
          ),
        ),

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
                childCount:
                    feedState.posts.length + (feedState.hasMore ? 1 : 0),
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
            Icon(Icons.people_outline,
                size: 64, color: theme.textTheme.bodySmall?.color),
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
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
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
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Semantics(
      label: context.l10n.communityLoadingCommunityFeed,
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
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.dividerColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 100, height: 12,
                              color: theme.dividerColor),
                          const SizedBox(height: 4),
                          Container(width: 60, height: 10,
                              color: theme.dividerColor),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(width: double.infinity, height: 12,
                      color: theme.dividerColor),
                  const SizedBox(height: 6),
                  Container(width: double.infinity, height: 12,
                      color: theme.dividerColor),
                  const SizedBox(height: 6),
                  Container(width: 200, height: 12,
                      color: theme.dividerColor),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      3,
                      (_) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 48, height: 28,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showComposeSheet(int? spaceId) {
    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ComposePostSheet(initialSpaceId: spaceId),
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
          tooltip: context.l10n.trainerAnnouncements,
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
            constraints:
                const BoxConstraints(minWidth: 18, minHeight: 18),
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
