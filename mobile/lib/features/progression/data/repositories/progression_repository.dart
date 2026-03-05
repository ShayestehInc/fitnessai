import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/progression_models.dart';

class ProgressionRepository {
  final ApiClient _apiClient;

  ProgressionRepository(this._apiClient);

  /// Fetches progression suggestions for a given program.
  ///
  /// The API returns `{suggestions: [...], new_suggestions_generated: N}`.
  Future<Map<String, dynamic>> fetchSuggestions(int programId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.progressionSuggestions(programId),
      );
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> rawSuggestions = data['suggestions'] ?? [];
      final suggestions = rawSuggestions
          .map((e) =>
              ProgressionSuggestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': suggestions,
        'new_suggestions_generated': data['new_suggestions_generated'] ?? 0,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            'Failed to load progression suggestions',
      };
    }
  }

  /// Approves a progression suggestion without applying it yet.
  Future<Map<String, dynamic>> approveSuggestion(int suggestionId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.apiBaseUrl}/workouts/progression-suggestions/$suggestionId/approve/',
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to approve suggestion',
      };
    }
  }

  /// Dismisses a progression suggestion.
  Future<Map<String, dynamic>> dismissSuggestion(int suggestionId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.apiBaseUrl}/workouts/progression-suggestions/$suggestionId/dismiss/',
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to dismiss suggestion',
      };
    }
  }

  /// Applies a progression suggestion to the program schedule.
  Future<Map<String, dynamic>> applySuggestion(int suggestionId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.apiBaseUrl}/workouts/progression-suggestions/$suggestionId/apply/',
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to apply suggestion',
      };
    }
  }

  /// Checks whether a deload is recommended for a given program.
  Future<Map<String, dynamic>> checkDeload(int programId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.deloadCheck(programId),
      );
      final recommendation = DeloadRecommendationModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': recommendation,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to check deload status',
      };
    }
  }

  /// Applies a deload to the given program for the specified week.
  Future<Map<String, dynamic>> applyDeload(
    int programId,
    int weekNumber,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.applyDeload(programId),
        data: {'week_number': weekNumber},
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to apply deload',
      };
    }
  }
}
