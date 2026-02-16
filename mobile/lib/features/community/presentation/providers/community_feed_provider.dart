import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/community_post_model.dart';
import '../../data/repositories/community_feed_repository.dart';

class CommunityFeedState {
  final List<CommunityPostModel> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const CommunityFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  CommunityFeedState copyWith({
    List<CommunityPostModel>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearError = false,
  }) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final communityFeedProvider =
    StateNotifierProvider<CommunityFeedNotifier, CommunityFeedState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunityFeedNotifier(CommunityFeedRepository(apiClient));
});

class CommunityFeedNotifier extends StateNotifier<CommunityFeedState> {
  final CommunityFeedRepository _repo;

  CommunityFeedNotifier(this._repo) : super(const CommunityFeedState());

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.getFeed(page: 1);
      state = state.copyWith(
        posts: response.results,
        isLoading: false,
        hasMore: response.next != null,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load community feed',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final response = await _repo.getFeed(page: nextPage);
      state = state.copyWith(
        posts: [...state.posts, ...response.results],
        isLoadingMore: false,
        hasMore: response.next != null,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> createPost({
    required String content,
    String contentFormat = 'plain',
    String? imagePath,
  }) async {
    try {
      final post = await _repo.createPost(
        content: content,
        contentFormat: contentFormat,
        imagePath: imagePath,
      );
      state = state.copyWith(posts: [post, ...state.posts]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePost(int postId) async {
    try {
      await _repo.deletePost(postId);
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleReaction({
    required int postId,
    required String reactionType,
  }) async {
    // Save previous state for rollback on error
    final previousPosts = state.posts;

    // Optimistic update: toggle reaction locally before API call
    state = state.copyWith(
      posts: state.posts.map((p) {
        if (p.id != postId) return p;
        final hasReaction = p.userReactions.contains(reactionType);
        final newUserReactions = hasReaction
            ? p.userReactions.where((r) => r != reactionType).toList()
            : [...p.userReactions, reactionType];
        final delta = hasReaction ? -1 : 1;
        final oldReactions = p.reactions;
        ReactionCounts newCounts;
        switch (reactionType) {
          case 'fire':
            newCounts = ReactionCounts(
              fire: (oldReactions.fire + delta).clamp(0, 999999),
              thumbsUp: oldReactions.thumbsUp,
              heart: oldReactions.heart,
            );
          case 'thumbs_up':
            newCounts = ReactionCounts(
              fire: oldReactions.fire,
              thumbsUp: (oldReactions.thumbsUp + delta).clamp(0, 999999),
              heart: oldReactions.heart,
            );
          case 'heart':
            newCounts = ReactionCounts(
              fire: oldReactions.fire,
              thumbsUp: oldReactions.thumbsUp,
              heart: (oldReactions.heart + delta).clamp(0, 999999),
            );
          default:
            newCounts = oldReactions;
        }
        return p.copyWith(
          reactions: newCounts,
          userReactions: newUserReactions,
        );
      }).toList(),
    );

    try {
      final response = await _repo.toggleReaction(
        postId: postId,
        reactionType: reactionType,
      );
      // Reconcile with server state
      state = state.copyWith(
        posts: state.posts.map((p) {
          if (p.id == postId) {
            return p.copyWith(
              reactions: response.reactions,
              userReactions: response.userReactions,
            );
          }
          return p;
        }).toList(),
      );
    } catch (_) {
      // Rollback to previous state on error
      state = state.copyWith(posts: previousPosts);
    }
  }

  /// Handle a new post from WebSocket.
  void onNewPost(CommunityPostModel post) {
    // Avoid duplicates
    if (state.posts.any((p) => p.id == post.id)) return;
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  /// Handle post deletion from WebSocket.
  void onPostDeleted(int postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
  }

  /// Increment comment count for a post (from WebSocket).
  void onNewComment(int postId) {
    state = state.copyWith(
      posts: state.posts.map((p) {
        if (p.id == postId) {
          return p.copyWith(commentCount: p.commentCount + 1);
        }
        return p;
      }).toList(),
    );
  }

  /// Update reaction counts for a post (from WebSocket).
  void onReactionUpdate(int postId, ReactionCounts reactions) {
    state = state.copyWith(
      posts: state.posts.map((p) {
        if (p.id == postId) {
          return p.copyWith(reactions: reactions);
        }
        return p;
      }).toList(),
    );
  }
}
