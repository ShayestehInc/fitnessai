import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/trainee_model.dart';
import '../models/trainer_stats_model.dart';
import '../models/invitation_model.dart';
import '../models/impersonation_session_model.dart';

class TrainerRepository {
  final ApiClient _apiClient;

  TrainerRepository(this._apiClient);

  // Dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.trainerDashboard);
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load dashboard',
      };
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.trainerStats);
      return {
        'success': true,
        'data': TrainerStatsModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load stats',
      };
    }
  }

  // Trainees
  Future<Map<String, dynamic>> getTrainees() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.trainerTrainees);
      final List<dynamic> results = response.data['results'] ?? response.data;
      final trainees = results.map((e) => TraineeModel.fromJson(e)).toList();
      return {
        'success': true,
        'data': trainees,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load trainees',
      };
    }
  }

  Future<Map<String, dynamic>> getTraineeDetail(int traineeId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.trainerTrainees}$traineeId/',
      );
      final model = TraineeDetailModel.fromJson(response.data);
      return {
        'success': true,
        'data': model,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load trainee details',
      };
    }
  }

  Future<Map<String, dynamic>> getTraineeActivity(int traineeId, {int days = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.trainerTrainees}$traineeId/activity/',
        queryParameters: {'days': days},
      );
      final List<dynamic> results = response.data['results'] ?? response.data;
      final activities = results.map((e) => ActivitySummary.fromJson(e)).toList();
      return {
        'success': true,
        'data': activities,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load activity',
      };
    }
  }

  Future<Map<String, dynamic>> getTraineeProgress(int traineeId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.trainerTrainees}$traineeId/progress/',
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load progress',
      };
    }
  }

  Future<Map<String, dynamic>> removeTrainee(int traineeId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.trainerTrainees}$traineeId/remove/',
      );
      return {
        'success': true,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to remove trainee',
      };
    }
  }

  Future<Map<String, dynamic>> updateTraineeGoals(
    int traineeId, {
    String? goal,
    String? activityLevel,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (goal != null) data['goal'] = goal;
      if (activityLevel != null) data['activity_level'] = activityLevel;

      final response = await _apiClient.dio.patch(
        '${ApiConstants.trainerTrainees}$traineeId/goals/',
        data: data,
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update goals',
      };
    }
  }

  // Invitations
  Future<Map<String, dynamic>> getInvitations() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.trainerInvitations);
      final List<dynamic> results = response.data['results'] ?? response.data;
      final invitations = results.map((e) => InvitationModel.fromJson(e)).toList();
      return {
        'success': true,
        'data': invitations,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load invitations',
      };
    }
  }

  Future<Map<String, dynamic>> createInvitation(CreateInvitationRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.trainerInvitations,
        data: request.toJson(),
      );
      return {
        'success': true,
        'data': InvitationModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? e.response?.data?['email']?[0] ?? 'Failed to create invitation',
      };
    }
  }

  Future<Map<String, dynamic>> resendInvitation(int invitationId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.trainerInvitations}$invitationId/resend/',
      );
      return {
        'success': true,
        'data': InvitationModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to resend invitation',
      };
    }
  }

  Future<Map<String, dynamic>> cancelInvitation(int invitationId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConstants.trainerInvitations}$invitationId/',
      );
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to cancel invitation',
      };
    }
  }

  // Impersonation
  Future<Map<String, dynamic>> startImpersonation(int traineeId, {bool isReadOnly = true}) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.startImpersonation}$traineeId/start/',
        data: {'is_read_only': isReadOnly},
      );
      return {
        'success': true,
        'data': ImpersonationResponse.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to start impersonation',
      };
    }
  }

  Future<Map<String, dynamic>> endImpersonation({int? sessionId}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.endImpersonation,
        data: sessionId != null ? {'session_id': sessionId} : null,
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to end impersonation',
      };
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getAdherenceAnalytics({int days = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerAnalyticsAdherence,
        queryParameters: {'days': days},
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load adherence analytics',
      };
    }
  }

  Future<Map<String, dynamic>> getProgressAnalytics() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerAnalyticsProgress,
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load progress analytics',
      };
    }
  }

  // Layout Config
  Future<Map<String, dynamic>> getTraineeLayoutConfig(int traineeId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.traineeLayoutConfig(traineeId),
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load layout config',
      };
    }
  }

  Future<Map<String, dynamic>> updateTraineeLayoutConfig(
    int traineeId, {
    required String layoutType,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.traineeLayoutConfig(traineeId),
        data: {'layout_type': layoutType},
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update layout config',
      };
    }
  }
}
