import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/session_models.dart';

class SessionRepository {
  final ApiClient _apiClient;

  SessionRepository(this._apiClient);

  Future<Map<String, dynamic>> getActiveSession() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.sessionsActive,
      );
      return {
        'success': true,
        'data': ActiveSessionModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {
          'success': true,
          'data': null,
        };
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load active session',
      };
    }
  }

  Future<Map<String, dynamic>> getSessionDetail(String id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.sessionDetail(id),
      );
      return {
        'success': true,
        'data': ActiveSessionModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load session',
      };
    }
  }

  Future<Map<String, dynamic>> startSession(String planSessionId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.sessionsStart,
        data: {'plan_session_id': planSessionId},
      );
      return {
        'success': true,
        'data': ActiveSessionModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to start session',
      };
    }
  }

  Future<Map<String, dynamic>> logSet({
    required String sessionId,
    required String slotId,
    required int setNumber,
    required int completedReps,
    required double loadValue,
    required String loadUnit,
    double? rpe,
    int? restActualSeconds,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{
        'slot_id': slotId,
        'set_number': setNumber,
        'completed_reps': completedReps,
        'load_value': loadValue,
        'load_unit': loadUnit,
      };
      if (rpe != null) data['rpe'] = rpe;
      if (restActualSeconds != null) {
        data['rest_actual_seconds'] = restActualSeconds;
      }
      if (notes != null && notes.isNotEmpty) data['notes'] = notes;

      final response = await _apiClient.dio.post(
        ApiConstants.sessionLogSet(sessionId),
        data: data,
      );
      return {
        'success': true,
        'data': ActiveSessionModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to log set',
      };
    }
  }

  Future<Map<String, dynamic>> skipSet({
    required String sessionId,
    required String slotId,
    required int setNumber,
    String? reason,
  }) async {
    try {
      final data = <String, dynamic>{
        'slot_id': slotId,
        'set_number': setNumber,
      };
      if (reason != null && reason.isNotEmpty) data['reason'] = reason;

      final response = await _apiClient.dio.post(
        ApiConstants.sessionSkipSet(sessionId),
        data: data,
      );
      return {
        'success': true,
        'data': ActiveSessionModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to skip set',
      };
    }
  }

  Future<Map<String, dynamic>> completeSession(String sessionId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.sessionComplete(sessionId),
      );
      return {
        'success': true,
        'data': SessionSummaryModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to complete session',
      };
    }
  }

  Future<Map<String, dynamic>> abandonSession(
    String sessionId, {
    String? reason,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) data['reason'] = reason;

      final response = await _apiClient.dio.post(
        ApiConstants.sessionAbandon(sessionId),
        data: data,
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to abandon session',
      };
    }
  }

  Future<Map<String, dynamic>> listSessions({
    String? status,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.sessions,
        queryParameters: queryParams,
      );

      final List<dynamic> results =
          response.data['results'] ?? response.data;
      final sessions =
          results.map((e) => ActiveSessionModel.fromJson(e)).toList();

      return {
        'success': true,
        'data': sessions,
        'count': response.data['count'] ?? sessions.length,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load sessions',
      };
    }
  }
}
