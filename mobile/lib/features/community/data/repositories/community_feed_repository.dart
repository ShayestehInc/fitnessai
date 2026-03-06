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

  /// Fetch paginated community feed with optional space filter and sort.
  Future<CommunityFeedResponse> getFeed({
    int page = 1,
    int? spaceId,
    String sort = 'latest',
  }) async {
    final params = <String, String>{
      'page': '$page',
      'sort': sort,
    };
    if (spaceId != null) {
      params['space'] = '$spaceId';
    }
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await _apiClient.dio.get(
      '${ApiConstants.communityFeed}?$queryString',
    );
    return CommunityFeedResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Create a text post with optional images, videos, and space.
  Future<CommunityPostModel> createPost({
    required String content,
    String contentFormat = 'plain',
    List<String> imagePaths = const [],
    List<String> videoPaths = const [],
    int? spaceId,
    void Function(int sent, int total)? onUploadProgress,
  }) async {
    final hasMedia = imagePaths.isNotEmpty || videoPaths.isNotEmpty;

    if (hasMedia) {
      final formMap = <String, dynamic>{
        'content': content,
        'content_format': contentFormat,
      };
      if (spaceId != null) {
        formMap['space'] = spaceId;
      }

      // Add images
      if (imagePaths.isNotEmpty) {
        final imageFiles = <MultipartFile>[];
        for (final path in imagePaths) {
          imageFiles.add(await MultipartFile.fromFile(path));
        }
        formMap['images'] = imageFiles;
      }

      // Add videos
      if (videoPaths.isNotEmpty) {
        final videoFiles = <MultipartFile>[];
        for (final path in videoPaths) {
          videoFiles.add(await MultipartFile.fromFile(path));
        }
        formMap['videos'] = videoFiles;
      }

      final formData = FormData.fromMap(formMap);
      final response = await _apiClient.dio.post(
        ApiConstants.communityFeed,
        data: formData,
        onSendProgress: onUploadProgress,
      );
      return CommunityPostModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

    // JSON post (no media)
    final data = <String, dynamic>{
      'content': content,
      'content_format': contentFormat,
    };
    if (spaceId != null) {
      data['space'] = spaceId;
    }
    final response = await _apiClient.dio.post(
      ApiConstants.communityFeed,
      data: data,
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

  /// Fetch threaded comments for a post.
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

  /// Create a comment on a post, optionally as a reply.
  Future<CommentModel> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    final data = <String, dynamic>{'content': content};
    if (parentCommentId != null) {
      data['parent_comment'] = parentCommentId;
    }
    final response = await _apiClient.dio.post(
      ApiConstants.communityPostComments(postId),
      data: data,
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
