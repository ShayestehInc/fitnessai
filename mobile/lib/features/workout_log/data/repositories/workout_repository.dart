import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/workout_models.dart';

class WorkoutRepository {
  final ApiClient _apiClient;

  WorkoutRepository(this._apiClient);

  /// Get daily workout summary
  Future<Map<String, dynamic>> getDailyWorkoutSummary(String date) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.workoutSummary,
        queryParameters: {'date': date},
      );

      if (response.statusCode == 200) {
        final summary = WorkoutSummary.fromJson(response.data);
        return {'success': true, 'summary': summary};
      }

      return {'success': false, 'error': 'Failed to get workout summary'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get workout summary',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user's programs
  Future<Map<String, dynamic>> getPrograms() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.programs);

      if (response.statusCode == 200) {
        // Handle both paginated response (results array) and direct list
        List<dynamic> data;
        if (response.data is List) {
          data = response.data;
        } else if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'] as List;
        } else {
          data = [];
        }
        final programs =
            data.map((json) => ProgramModel.fromJson(json)).toList();
        return {'success': true, 'programs': programs};
      }

      return {'success': false, 'error': 'Failed to get programs'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get programs',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get active program
  Future<Map<String, dynamic>> getActiveProgram() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.programs);

      if (response.statusCode == 200) {
        List<dynamic> data;
        if (response.data is List) {
          data = response.data;
        } else if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'] as List;
        } else {
          data = [];
        }

        final programs =
            data.map((json) => ProgramModel.fromJson(json)).toList();

        // Find active program
        ProgramModel? activeProgram;
        for (final p in programs) {
          if (p.isActive) {
            activeProgram = p;
            break;
          }
        }
        // If no active found, use first program
        activeProgram ??= programs.isNotEmpty ? programs.first : null;

        if (activeProgram != null) {
          return {'success': true, 'program': activeProgram};
        }
        return {'success': false, 'error': 'No active program found'};
      }

      return {'success': false, 'error': 'Failed to get programs'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get programs',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get workout history (daily logs)
  Future<Map<String, dynamic>> getWorkoutHistory() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.dailyLogs);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        return {'success': true, 'logs': data};
      }

      return {'success': false, 'error': 'Failed to get workout history'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get workout history',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Submit pre-workout readiness survey
  /// This notifies the trainer about the trainee's readiness before the workout
  Future<Map<String, dynamic>> submitReadinessSurvey({
    required String workoutName,
    required Map<String, dynamic> surveyData,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.workoutReadinessSurvey,
        data: {
          'workout_name': workoutName,
          'survey_data': surveyData,
          'survey_type': 'readiness',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }

      return {'success': false, 'error': 'Failed to submit survey'};
    } on DioException catch (e) {
      // Silently fail - don't interrupt workout if survey fails
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to submit survey',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Submit post-workout survey with workout data
  /// This notifies the trainer about how the workout went
  Future<Map<String, dynamic>> submitPostWorkoutSurvey({
    required Map<String, dynamic> workoutSummary,
    required Map<String, dynamic> surveyData,
    Map<String, dynamic>? readinessSurvey,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.workoutPostSurvey,
        data: {
          'workout_summary': workoutSummary,
          'survey_data': surveyData,
          'readiness_survey': readinessSurvey,
          'survey_type': 'post_workout',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }

      return {'success': false, 'error': 'Failed to submit survey'};
    } on DioException catch (e) {
      // Silently fail - don't block completion if survey fails
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to submit survey',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
