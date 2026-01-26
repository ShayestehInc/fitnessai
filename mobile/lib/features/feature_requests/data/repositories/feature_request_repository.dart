import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/feature_request_model.dart';

class FeatureRequestRepository {
  final ApiClient _apiClient;

  FeatureRequestRepository(this._apiClient);

  Future<Map<String, dynamic>> getFeatureRequests({
    String? status,
    String? category,
    String? search,
    String sort = 'votes',
  }) async {
    try {
      final Map<String, dynamic> params = {'sort': sort};
      if (status != null) params['status'] = status;
      if (category != null) params['category'] = category;
      if (search != null) params['search'] = search;

      final response = await _apiClient.dio.get(
        ApiConstants.featureRequests,
        queryParameters: params,
      );
      final List<dynamic> results = response.data['results'] ?? response.data;
      final features = results.map((e) => FeatureRequestModel.fromJson(e)).toList();
      return {
        'success': true,
        'data': features,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load feature requests',
      };
    }
  }

  Future<Map<String, dynamic>> getFeatureRequest(int featureId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.featureRequests}$featureId/',
      );
      return {
        'success': true,
        'data': FeatureRequestModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load feature request',
      };
    }
  }

  Future<Map<String, dynamic>> createFeatureRequest({
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.featureRequests,
        data: {
          'title': title,
          'description': description,
          'category': category,
        },
      );
      return {
        'success': true,
        'data': FeatureRequestModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      final errors = e.response?.data;
      String errorMsg = 'Failed to create feature request';
      if (errors is Map) {
        if (errors['title'] != null) errorMsg = errors['title'][0];
        else if (errors['description'] != null) errorMsg = errors['description'][0];
      }
      return {
        'success': false,
        'error': errorMsg,
      };
    }
  }

  Future<Map<String, dynamic>> vote(int featureId, String voteType) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.featureRequests}$featureId/vote/',
        data: {'vote_type': voteType},
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to vote',
      };
    }
  }

  Future<Map<String, dynamic>> addComment(int featureId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.featureRequests}$featureId/comments/',
        data: {'content': content},
      );
      return {
        'success': true,
        'data': FeatureCommentModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to add comment',
      };
    }
  }

  Future<Map<String, dynamic>> getComments(int featureId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.featureRequests}$featureId/comments/',
      );
      final List<dynamic> results = response.data['results'] ?? response.data;
      final comments = results.map((e) => FeatureCommentModel.fromJson(e)).toList();
      return {
        'success': true,
        'data': comments,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load comments',
      };
    }
  }
}
