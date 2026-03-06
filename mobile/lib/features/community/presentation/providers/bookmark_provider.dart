import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/community_post_model.dart';
import '../../data/repositories/bookmark_repository.dart';

// ---------------------------------------------------------------------------
// Bookmarked posts
// ---------------------------------------------------------------------------

class BookmarksState {
  final List<CommunityPostModel> posts;
  final bool isLoading;
  final String? error;

  const BookmarksState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  BookmarksState copyWith({
    List<CommunityPostModel>? posts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BookmarksState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, BookmarksState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookmarksNotifier(BookmarkRepository(apiClient));
});

class BookmarksNotifier extends StateNotifier<BookmarksState> {
  final BookmarkRepository _repo;

  BookmarksNotifier(this._repo) : super(const BookmarksState());

  Future<void> loadBookmarks({int? collectionId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final posts = await _repo.getBookmarks(collectionId: collectionId);
      state = state.copyWith(posts: posts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load saved items',
      );
    }
  }

  Future<bool> toggleBookmark(int postId) async {
    try {
      final result = await _repo.toggleBookmark(postId);
      if (!result.isBookmarked) {
        // Remove from list
        state = state.copyWith(
          posts: state.posts.where((p) => p.id != postId).toList(),
        );
      }
      return result.isBookmarked;
    } catch (_) {
      return false;
    }
  }
}
