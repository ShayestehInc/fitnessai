import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/lift_models.dart';

class LiftRepository {
  final ApiClient _apiClient;

  LiftRepository(this._apiClient);

  /// Fetches paginated lift set logs, optionally filtered by exercise and date range.
  Future<Map<String, dynamic>> getLiftSetLogs({
    int? exerciseId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (exerciseId != null) queryParams['exercise_id'] = exerciseId;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await _apiClient.dio.get(
        ApiConstants.liftSetLogs,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] ?? [];
      final logs = results
          .map((e) => LiftSetLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': logs,
        'count': data['count'] ?? logs.length,
        'next': data['next'],
        'previous': data['previous'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load lift set logs',
      };
    }
  }

  /// Fetches paginated lift maxes for all exercises.
  Future<Map<String, dynamic>> getLiftMaxes({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.liftMaxes,
        queryParameters: {'page': page},
      );
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] ?? [];
      final maxes = results
          .map((e) => LiftMaxModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': maxes,
        'count': data['count'] ?? maxes.length,
        'next': data['next'],
        'previous': data['previous'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load lift maxes',
      };
    }
  }

  /// Fetches e1RM and TM history for a specific exercise.
  Future<Map<String, dynamic>> getLiftMaxHistory(int exerciseId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.liftMaxHistory,
        queryParameters: {'exercise_id': exerciseId},
      );
      final data = response.data as Map<String, dynamic>;
      final e1rmHistory = (data['e1rm_history'] as List<dynamic>? ?? [])
          .map((e) => E1rmHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final tmHistory = (data['tm_history'] as List<dynamic>? ?? [])
          .map((e) => E1rmHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': {
          'exercise_id': data['exercise_id'],
          'exercise_name': data['exercise_name'],
          'e1rm_history': e1rmHistory,
          'tm_history': tmHistory,
        },
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to load lift max history',
      };
    }
  }

  /// Fetches session workload for a given date.
  Future<Map<String, dynamic>> getSessionWorkload(
    String sessionDate, {
    int? traineeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'session_date': sessionDate};
      if (traineeId != null) queryParams['trainee_id'] = traineeId;

      final response = await _apiClient.dio.get(
        ApiConstants.workloadSession,
        queryParameters: queryParams,
      );
      final workload = WorkloadSessionModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': workload,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to load session workload',
      };
    }
  }

  /// Fetches weekly workload with breakdowns.
  Future<Map<String, dynamic>> getWeeklyWorkload({
    String? weekStart,
    int? traineeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (weekStart != null) queryParams['week_start'] = weekStart;
      if (traineeId != null) queryParams['trainee_id'] = traineeId;

      final response = await _apiClient.dio.get(
        ApiConstants.workloadWeekly,
        queryParameters: queryParams,
      );
      final weekly = WorkloadWeeklyModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': weekly,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to load weekly workload',
      };
    }
  }

  /// Fetches workload trends (ACWR, rolling averages, spike/dip flags).
  Future<Map<String, dynamic>> getWorkloadTrends({
    int weeksBack = 8,
    int? traineeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'weeks_back': weeksBack};
      if (traineeId != null) queryParams['trainee_id'] = traineeId;

      final response = await _apiClient.dio.get(
        ApiConstants.workloadTrends,
        queryParameters: queryParams,
      );
      final trends = WorkloadTrendsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': trends,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to load workload trends',
      };
    }
  }
}
