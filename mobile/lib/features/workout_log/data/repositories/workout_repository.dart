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
        final List<dynamic> data = response.data is List ? response.data : [];
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
        final List<dynamic> data = response.data is List ? response.data : [];
        final programs =
            data.map((json) => ProgramModel.fromJson(json)).toList();

        // Find active program
        final activeProgram = programs.firstWhere(
          (p) => p.isActive,
          orElse: () => programs.isNotEmpty ? programs.first : null as ProgramModel,
        );

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
}
