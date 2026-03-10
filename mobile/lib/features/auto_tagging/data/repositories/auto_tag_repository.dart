import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/auto_tag_model.dart';

class AutoTagRepository {
  final ApiClient _apiClient;

  AutoTagRepository(this._apiClient);

  Future<Map<String, dynamic>> getAutoTagDraft(int exerciseId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.exerciseAutoTagDraft(exerciseId),
      );
      return {
        'success': true,
        'data': AutoTagDraftModel.fromJson(
          response.data as Map<String, dynamic>,
        ),
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {
          'success': true,
          'data': null,
        };
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load auto-tag draft',
      };
    }
  }

  Future<Map<String, dynamic>> triggerAutoTag(int exerciseId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.exerciseAutoTag(exerciseId),
      );
      return {
        'success': true,
        'data': AutoTagDraftModel.fromJson(
          response.data as Map<String, dynamic>,
        ),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to trigger auto-tagging',
      };
    }
  }

  Future<Map<String, dynamic>> applyTags(int exerciseId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.exerciseAutoTagApply(exerciseId),
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to apply tags',
      };
    }
  }

  Future<Map<String, dynamic>> rejectTags(int exerciseId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.exerciseAutoTagReject(exerciseId),
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to reject tags',
      };
    }
  }

  Future<Map<String, dynamic>> retryAutoTag(int exerciseId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.exerciseAutoTagRetry(exerciseId),
      );
      return {
        'success': true,
        'data': AutoTagDraftModel.fromJson(
          response.data as Map<String, dynamic>,
        ),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to retry auto-tagging',
      };
    }
  }

  Future<Map<String, dynamic>> getTagHistory(int exerciseId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.exerciseTagHistory(exerciseId),
      );
      final data = response.data;
      final List<dynamic> results =
          data is List ? data : (data['results'] ?? []);
      final entries = results
          .map((e) => TagHistoryEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'success': true,
        'data': entries,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load tag history',
      };
    }
  }
}
