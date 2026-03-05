import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/workout_template_model.dart';

class QuickLogRepository {
  final ApiClient _apiClient;

  QuickLogRepository(this._apiClient);

  /// Fetches all available workout templates, optionally filtered by [category].
  Future<Map<String, dynamic>> getWorkoutTemplates({
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.workoutTemplates,
        queryParameters: queryParams,
      );

      final List<dynamic> results =
          response.data['results'] ?? response.data;
      final templates =
          results.map((e) => WorkoutTemplateModel.fromJson(e as Map<String, dynamic>)).toList();

      return {
        'success': true,
        'data': templates,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load workout templates',
      };
    }
  }

  /// Submits a quick-log entry.
  ///
  /// [templateId] — the workout template used.
  /// [durationMinutes] — how long the activity lasted.
  /// [caloriesBurned] — estimated calories burned.
  /// [notes] — optional free-text notes.
  Future<Map<String, dynamic>> submitQuickLog({
    required int templateId,
    required int durationMinutes,
    required double caloriesBurned,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{
        'template_id': templateId,
        'duration_minutes': durationMinutes,
        'calories_burned': caloriesBurned,
      };
      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }

      final response = await _apiClient.dio.post(
        ApiConstants.quickLog,
        data: data,
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to submit quick log',
      };
    }
  }
}
