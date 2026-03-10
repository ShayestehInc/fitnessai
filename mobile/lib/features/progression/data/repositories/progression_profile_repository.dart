import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/progression_profile_model.dart';

class ProgressionProfileRepository {
  final ApiClient _apiClient;

  ProgressionProfileRepository(this._apiClient);

  /// Lists progression profiles for the current trainee.
  Future<Map<String, dynamic>> listProfiles() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.progressionProfiles,
      );
      final data = response.data;
      final List<dynamic> results =
          data is Map ? (data['results'] ?? []) : (data as List);
      final profiles = results
          .map((e) =>
              ProgressionProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': profiles,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to load progression profiles',
      };
    }
  }

  /// Fetches a single progression profile by ID.
  Future<Map<String, dynamic>> getProfile(int profileId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.progressionProfileDetail(profileId),
      );
      final profile = ProgressionProfileModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': profile,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to load profile',
      };
    }
  }

  /// Updates a progression profile (strategy, config).
  Future<Map<String, dynamic>> updateProfile(
    int profileId, {
    String? strategy,
    Map<String, dynamic>? config,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (strategy != null) body['strategy'] = strategy;
      if (config != null) body['config'] = config;
      final response = await _apiClient.dio.patch(
        ApiConstants.progressionProfileDetail(profileId),
        data: body,
      );
      final profile = ProgressionProfileModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': profile,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to update profile',
      };
    }
  }

  /// Lists plan-based progression suggestions with optional pagination.
  Future<Map<String, dynamic>> listSuggestions({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.progressionSuggestionsList,
        queryParameters: {'page': page},
      );
      final data = response.data;
      final List<dynamic> results =
          data is Map ? (data['results'] ?? []) : (data as List);
      final suggestions = results
          .map((e) => ProgressionPlanSuggestionModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': suggestions,
        'count': data is Map
            ? (data['count'] ?? suggestions.length)
            : suggestions.length,
        'next': data is Map ? data['next'] : null,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to load suggestions',
      };
    }
  }

  /// Approves a plan-based progression suggestion.
  Future<Map<String, dynamic>> approveSuggestion(int suggestionId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.progressionSuggestionApprove(suggestionId),
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to approve suggestion',
      };
    }
  }

  /// Dismisses a plan-based progression suggestion.
  Future<Map<String, dynamic>> dismissSuggestion(int suggestionId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.progressionSuggestionDismiss(suggestionId),
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to dismiss suggestion',
      };
    }
  }
}
