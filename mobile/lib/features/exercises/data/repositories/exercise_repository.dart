import 'dart:io';
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

  Future<Map<String, dynamic>> updateExercise(int exerciseId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiConstants.exercises}$exerciseId/',
        data: data,
      );
      return {
        'success': true,
        'data': ExerciseModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update exercise',
      };
    }
  }

  /// Uploads an image file for an exercise.
  ///
  /// Returns a map with 'success' boolean and either 'image_url' on success
  /// or 'error' message on failure.
  Future<Map<String, dynamic>> uploadExerciseImage(int exerciseId, File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        '${ApiConstants.exercises}$exerciseId/upload-image/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return {
        'success': true,
        'image_url': response.data['image_url'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to upload image',
      };
    }
  }

  /// Uploads a video file for an exercise.
  ///
  /// Returns a map with 'success' boolean and either 'video_url' on success
  /// or 'error' message on failure.
  Future<Map<String, dynamic>> uploadExerciseVideo(int exerciseId, File videoFile) async {
    try {
      final fileName = videoFile.path.split('/').last;
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        '${ApiConstants.exercises}$exerciseId/upload-video/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return {
        'success': true,
        'video_url': response.data['video_url'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to upload video',
      };
    }
  }
}
