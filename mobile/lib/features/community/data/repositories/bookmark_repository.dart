import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/bookmark_model.dart';
import '../models/community_post_model.dart';

/// Repository for Bookmark API calls.
class BookmarkRepository {
  final ApiClient _apiClient;

  BookmarkRepository(this._apiClient);

  /// Toggle bookmark on a post.
  Future<BookmarkToggleResult> toggleBookmark(int postId) async {
    final response = await _apiClient.dio.post(
      ApiConstants.communityBookmarkToggle,
      data: {'post_id': postId},
    );
    final data = response.data as Map<String, dynamic>;
    return BookmarkToggleResult(
      isBookmarked: data['is_bookmarked'] as bool,
      bookmarkId: data['bookmark_id'] as int?,
    );
  }

  /// Fetch user's bookmarked posts (returned as full post objects).
  Future<List<CommunityPostModel>> getBookmarks({int? collectionId}) async {
    String url = ApiConstants.communityBookmarks;
    if (collectionId != null) {
      url += '?collection=$collectionId';
    }
    final response = await _apiClient.dio.get(url);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => CommunityPostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch user's bookmark collections.
  Future<List<BookmarkCollectionModel>> getCollections() async {
    final response = await _apiClient.dio.get(
      ApiConstants.communityBookmarkCollections,
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => BookmarkCollectionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a bookmark collection.
  Future<BookmarkCollectionModel> createCollection(String name) async {
    final response = await _apiClient.dio.post(
      ApiConstants.communityBookmarkCollections,
      data: {'name': name},
    );
    return BookmarkCollectionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

/// Result of a bookmark toggle operation.
class BookmarkToggleResult {
  final bool isBookmarked;
  final int? bookmarkId;

  const BookmarkToggleResult({
    required this.isBookmarked,
    this.bookmarkId,
  });
}
