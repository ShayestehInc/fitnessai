import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/community_post_model.dart';

/// Repository for community feed API calls.
class CommunityFeedRepository {
  final ApiClient _apiClient;

  CommunityFeedRepository(this._apiClient);

  /// Fetch paginated community feed.
  Future<CommunityFeedResponse> getFeed({int page = 1}) async {
    final response = await _apiClient.dio.get(
      '${ApiConstants.communityFeed}?page=$page',
    );
    return CommunityFeedResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Create a text post.
  Future<CommunityPostModel> createPost(String content) async {
    final response = await _apiClient.dio.post(
      ApiConstants.communityFeed,
      data: {'content': content},
    );
    return CommunityPostModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a post.
  Future<void> deletePost(int postId) async {
    await _apiClient.dio.delete(ApiConstants.communityPostDelete(postId));
  }

  /// Toggle a reaction on a post.
  Future<ReactionToggleResponse> toggleReaction({
    required int postId,
    required String reactionType,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.communityPostReact(postId),
      data: {'reaction_type': reactionType},
    );
    return ReactionToggleResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
