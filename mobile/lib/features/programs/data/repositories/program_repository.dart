import 'dart:io';
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

  /// Rename a program template
  Future<Map<String, dynamic>> renameTemplate(int templateId, String newName) async {
    try {
      await _apiClient.dio.patch(
        '${ApiConstants.programTemplates}$templateId/',
        data: {'name': newName},
      );
      return {
        'success': true,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to rename template',
      };
    }
  }

  /// Rename a trainee program
  Future<Map<String, dynamic>> renameProgram(int programId, String newName) async {
    try {
      await _apiClient.dio.patch(
        '${ApiConstants.programs}$programId/',
        data: {'name': newName},
      );
      return {
        'success': true,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to rename program',
      };
    }
  }

  /// Update a program template's image URL
  Future<Map<String, dynamic>> updateTemplateImage(int templateId, String? imageUrl) async {
    try {
      await _apiClient.dio.patch(
        '${ApiConstants.programTemplates}$templateId/',
        data: {'image_url': imageUrl},
      );
      return {
        'success': true,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update template image',
      };
    }
  }

  /// Update a trainee program's image URL
  Future<Map<String, dynamic>> updateProgramImage(int programId, String? imageUrl) async {
    try {
      await _apiClient.dio.patch(
        '${ApiConstants.programs}$programId/',
        data: {'image_url': imageUrl},
      );
      return {
        'success': true,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update program image',
      };
    }
  }

  /// Upload an image file for a program or template
  Future<Map<String, dynamic>> uploadProgramImage(int id, File imageFile, {required bool isTemplate}) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final endpoint = isTemplate
          ? '${ApiConstants.programTemplates}$id/upload-image/'
          : '${ApiConstants.programs}$id/upload-image/';

      final response = await _apiClient.dio.post(
        endpoint,
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
}
