import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/program_import_model.dart';

class ProgramImportRepository {
  final ApiClient _apiClient;

  ProgramImportRepository(this._apiClient);

  /// Fetch paginated list of program imports.
  Future<Map<String, dynamic>> listImports({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.programImports,
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is List
            ? data as List<dynamic>
            : (data is Map && data.containsKey('results'))
                ? data['results'] as List<dynamic>
                : [];

        final imports = results
            .map((json) =>
                ProgramImportModel.fromJson(json as Map<String, dynamic>))
            .toList();

        final hasNext = data is Map && data['next'] != null;

        return {'success': true, 'imports': imports, 'has_next': hasNext};
      }

      return {'success': false, 'error': 'Failed to fetch program imports'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to fetch program imports',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch detail of a specific program import.
  Future<Map<String, dynamic>> getDetail(String importId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.programImportDetail(importId),
      );

      if (response.statusCode == 200) {
        final importModel = ProgramImportModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'import': importModel};
      }

      return {'success': false, 'error': 'Failed to fetch import detail'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Program import not found'};
      }
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to fetch import detail',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Upload a file for program import (multipart).
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      final response = await _apiClient.dio.post(
        ApiConstants.programImportUpload,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final importModel = ProgramImportModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'import': importModel};
      }

      return {'success': false, 'error': 'Failed to upload file'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to upload file',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Confirm a parsed program import.
  Future<Map<String, dynamic>> confirmImport(String importId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.programImportConfirm(importId),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final importModel = ProgramImportModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'import': importModel};
      }

      return {'success': false, 'error': 'Failed to confirm import'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to confirm import',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
