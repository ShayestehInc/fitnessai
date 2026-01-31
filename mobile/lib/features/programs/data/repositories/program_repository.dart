import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/program_model.dart';

class ProgramRepository {
  final ApiClient _apiClient;

  ProgramRepository(this._apiClient);

  Future<Map<String, dynamic>> getProgramTemplates({
    String? goalType,
    String? difficulty,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (goalType != null) queryParams['goal_type'] = goalType;
      if (difficulty != null) queryParams['difficulty_level'] = difficulty;

      final response = await _apiClient.dio.get(
        ApiConstants.programTemplates,
        queryParameters: queryParams,
      );

      final List<dynamic> results = response.data['results'] ?? response.data;
      final templates = results.map((e) => ProgramTemplateModel.fromJson(e)).toList();

      return {
        'success': true,
        'data': templates,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load templates',
      };
    }
  }

  Future<Map<String, dynamic>> getTraineePrograms(int traineeId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.trainerTrainees}$traineeId/programs/',
      );

      final List<dynamic> results = response.data['results'] ?? response.data;
      final programs = results.map((e) => TraineeProgramModel.fromJson(e)).toList();

      return {
        'success': true,
        'data': programs,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load programs',
      };
    }
  }

  Future<Map<String, dynamic>> createProgramTemplate(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.programTemplates,
        data: data,
      );
      return {
        'success': true,
        'data': ProgramTemplateModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to create template',
      };
    }
  }

  Future<Map<String, dynamic>> assignProgramToTrainee(int traineeId, int templateId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.programTemplates}$templateId/assign/',
        data: {'trainee_id': traineeId},
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to assign program',
      };
    }
  }

  /// Get all programs created by this trainer (for their trainees)
  Future<Map<String, dynamic>> getAllTrainerPrograms() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.programs);

      final List<dynamic> results = response.data['results'] ?? response.data;
      final programs = results.map((e) => TraineeProgramModel.fromJson(e)).toList();

      return {
        'success': true,
        'data': programs,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load programs',
      };
    }
  }

  /// Get trainer's custom templates (non-public ones they created)
  Future<Map<String, dynamic>> getMyTemplates() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.programTemplates);

      final List<dynamic> results = response.data['results'] ?? response.data;
      final templates = results
          .map((e) => ProgramTemplateModel.fromJson(e))
          .where((t) => !t.isPublic) // Only custom templates
          .toList();

      return {
        'success': true,
        'data': templates,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load templates',
      };
    }
  }

  /// Delete a program template
  Future<Map<String, dynamic>> deleteTemplate(int templateId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConstants.programTemplates}$templateId/',
      );
      return {
        'success': true,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to delete template',
      };
    }
  }
}
