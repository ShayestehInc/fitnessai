import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/exercise_model.dart';

class ExerciseRepository {
  final ApiClient _apiClient;

  ExerciseRepository(this._apiClient);

  Future<Map<String, dynamic>> getExercises({
    String? muscleGroup,
    String? equipment,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (muscleGroup != null && muscleGroup.isNotEmpty) {
        queryParams['muscle_group'] = muscleGroup;
      }
      if (equipment != null && equipment.isNotEmpty) {
        queryParams['equipment'] = equipment;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.exercises,
        queryParameters: queryParams,
      );

      final List<dynamic> results = response.data['results'] ?? response.data;
      final exercises = results.map((e) => ExerciseModel.fromJson(e)).toList();

      return {
        'success': true,
        'data': exercises,
        'count': response.data['count'] ?? exercises.length,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load exercises',
      };
    }
  }

  Future<Map<String, dynamic>> getExerciseDetail(int exerciseId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.exercises}$exerciseId/',
      );
      return {
        'success': true,
        'data': ExerciseModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load exercise',
      };
    }
  }

  Future<Map<String, dynamic>> createCustomExercise(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.exercises,
        data: data,
      );
      return {
        'success': true,
        'data': ExerciseModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to create exercise',
      };
    }
  }
}
