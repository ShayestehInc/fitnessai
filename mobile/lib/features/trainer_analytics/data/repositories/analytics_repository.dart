import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/analytics_models.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository(this._apiClient);

  Future<Map<String, dynamic>> getCorrelations({int days = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerAnalyticsCorrelations,
        queryParameters: {'days': days},
      );
      return {
        'success': true,
        'data': CorrelationOverviewModel.fromJson(response.data as Map<String, dynamic>),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load correlations',
      };
    }
  }

  Future<Map<String, dynamic>> getTraineePatterns({
    required int traineeId,
    int days = 30,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerTraineePatterns(traineeId),
        queryParameters: {'days': days},
      );
      return {
        'success': true,
        'data': TraineePatternsModel.fromJson(response.data as Map<String, dynamic>),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load trainee patterns',
      };
    }
  }

  Future<Map<String, dynamic>> getCohortAnalysis({
    int days = 30,
    double threshold = 0.7,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerCohortAnalysis,
        queryParameters: {'days': days, 'threshold': threshold},
      );
      final data = response.data as Map<String, dynamic>;
      final comparisons = (data['comparisons'] as List<dynamic>? ?? [])
          .map((e) => CohortComparisonModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': comparisons,
        'period_days': data['period_days'],
        'threshold': data['threshold'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load cohort analysis',
      };
    }
  }

  Future<Map<String, dynamic>> getAuditSummary({int days = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerAuditSummary,
        queryParameters: {'days': days},
      );
      return {
        'success': true,
        'data': AuditSummaryModel.fromJson(response.data as Map<String, dynamic>),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load audit summary',
      };
    }
  }

  Future<Map<String, dynamic>> getAuditTimeline({
    int days = 30,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerAuditTimeline,
        queryParameters: {'days': days, 'limit': limit, 'offset': offset},
      );
      final data = response.data as Map<String, dynamic>;
      final entries = (data['entries'] as List<dynamic>? ?? [])
          .map((e) => AuditTimelineEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': entries,
        'count': data['count'] ?? entries.length,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load audit timeline',
      };
    }
  }
}
