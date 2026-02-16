import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/comment_model.dart';
import '../models/community_post_model.dart';
import '../models/leaderboard_model.dart';

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

  /// Create a text post (with optional image and content format).
  Future<CommunityPostModel> createPost({
    required String content,
    String contentFormat = 'plain',
    String? imagePath,
  }) async {
    if (imagePath != null) {
      // Multipart upload
      final formData = FormData.fromMap({
        'content': content,
        'content_format': contentFormat,
        'image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _apiClient.dio.post(
        ApiConstants.communityFeed,
        data: formData,
      );
      return CommunityPostModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

    // JSON post (no image)
    final response = await _apiClient.dio.post(
      ApiConstants.communityFeed,
      data: {
        'content': content,
        'content_format': contentFormat,
      },
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

  // -----------------------------------------------------------------------
  // Comments
  // -----------------------------------------------------------------------

  /// Fetch comments for a post.
  Future<List<CommentModel>> getComments({
    required int postId,
    int page = 1,
  }) async {
    final response = await _apiClient.dio.get(
      '${ApiConstants.communityPostComments(postId)}?page=$page',
    );
    final data = response.data;
    // Handle paginated or flat list response
    final List<dynamic> results;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      results = data['results'] as List<dynamic>;
    } else if (data is List) {
      results = data;
    } else {
      results = [];
    }
    return results
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a comment on a post.
  Future<CommentModel> createComment({
    required int postId,
    required String content,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.communityPostComments(postId),
      data: {'content': content},
    );
    return CommentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a comment.
  Future<void> deleteComment({
    required int postId,
    required int commentId,
  }) async {
    await _apiClient.dio.delete(
      ApiConstants.communityCommentDelete(postId, commentId),
    );
  }

  // -----------------------------------------------------------------------
  // Leaderboard
  // -----------------------------------------------------------------------

  /// Fetch leaderboard data.
  Future<LeaderboardResponse> getLeaderboard({
    String metricType = 'workout_count',
    String timePeriod = 'weekly',
  }) async {
    final response = await _apiClient.dio.get(
      '${ApiConstants.communityLeaderboard}?metric_type=$metricType&time_period=$timePeriod',
    );
    return LeaderboardResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
