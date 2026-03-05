import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/checkin_models.dart';

class CheckInRepository {
  final ApiClient _apiClient;

  CheckInRepository(this._apiClient);

  /// Fetches all check-in templates for the current trainer.
  Future<Map<String, dynamic>> fetchTemplates() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.checkinTemplates,
      );

      if (response.statusCode == 200) {
        final List<dynamic> results =
            response.data is List ? response.data : (response.data['results'] ?? []);
        final templates = results
            .map((e) => CheckInTemplateModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': templates};
      }

      return {'success': false, 'error': 'Failed to load templates'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load templates',
      };
    }
  }

  /// Creates a new check-in template.
  Future<Map<String, dynamic>> createTemplate(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.checkinTemplates,
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final template = CheckInTemplateModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'data': template};
      }

      return {'success': false, 'error': 'Failed to create template'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to create template',
      };
    }
  }

  /// Assigns a check-in template to a trainee with a due date.
  Future<Map<String, dynamic>> assignTemplate({
    required int templateId,
    required int traineeId,
    required String dueDate,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.checkinTemplateAssign(templateId),
        data: {
          'template_id': templateId,
          'trainee_id': traineeId,
          'next_due_date': dueDate,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'error': 'Failed to assign template'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to assign template',
      };
    }
  }

  /// Fetches pending check-in assignments for the current trainee.
  Future<Map<String, dynamic>> fetchPendingAssignments() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.checkinResponsesPending,
      );

      if (response.statusCode == 200) {
        final List<dynamic> results =
            response.data is List ? response.data : (response.data['results'] ?? []);
        final assignments = results
            .map((e) => CheckInAssignmentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': assignments};
      }

      return {'success': false, 'error': 'Failed to load pending check-ins'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load pending check-ins',
      };
    }
  }

  /// Submits a check-in response for a given assignment.
  Future<Map<String, dynamic>> submitResponse({
    required int assignmentId,
    required List<Map<String, dynamic>> responses,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.checkinResponses,
        data: {
          'assignment_id': assignmentId,
          'responses': responses,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'error': 'Failed to submit check-in'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to submit check-in',
      };
    }
  }

  /// Fetches check-in responses, optionally filtered by trainee ID.
  Future<Map<String, dynamic>> fetchResponses({int? traineeId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (traineeId != null) {
        queryParams['trainee_id'] = traineeId;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.checkinResponses,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> results =
            response.data is List ? response.data : (response.data['results'] ?? []);
        final checkinResponses = results
            .map((e) => CheckInResponseModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': checkinResponses};
      }

      return {'success': false, 'error': 'Failed to load responses'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load responses',
      };
    }
  }

  /// Updates trainer notes on a check-in response.
  Future<Map<String, dynamic>> updateTrainerNotes({
    required int responseId,
    required String notes,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiConstants.checkinResponses}$responseId/',
        data: {'trainer_notes': notes},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'error': 'Failed to update notes'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update notes',
      };
    }
  }
}
