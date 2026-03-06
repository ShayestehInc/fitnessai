import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/community_post_card.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Screen displaying the user's bookmarked / saved posts.
class SavedItemsScreen extends ConsumerStatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  ConsumerState<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends ConsumerState<SavedItemsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookmarksProvider.notifier).loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookmarksState = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.communitySavedPosts),
        elevation: 0,
      ),
      body: AdaptiveRefreshIndicator(
        onRefresh: () =>
            ref.read(bookmarksProvider.notifier).loadBookmarks(),
        child: _buildBody(theme, bookmarksState),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, BookmarksState bookmarksState) {
    if (bookmarksState.isLoading && bookmarksState.posts.isEmpty) {
      return const Center(child: AdaptiveSpinner());
    }

    if (bookmarksState.error != null && bookmarksState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              bookmarksState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () =>
                  ref.read(bookmarksProvider.notifier).loadBookmarks(),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (bookmarksState.posts.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.separated(
      physics: adaptiveAlwaysScrollablePhysics(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: bookmarksState.posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          CommunityPostCard(post: bookmarksState.posts[index]),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border,
                size: 64, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              'No saved posts',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark posts to find them here later.',
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
}
