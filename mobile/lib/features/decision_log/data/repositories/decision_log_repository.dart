import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/decision_log_model.dart';

class DecisionLogRepository {
  final ApiClient _apiClient;

  DecisionLogRepository(this._apiClient);

  Future<Map<String, dynamic>> listDecisionLogs({
    String? decisionType,
    String? actorType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> params = {'page': page};
      if (decisionType != null) params['decision_type'] = decisionType;
      if (actorType != null) params['actor_type'] = actorType;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;

      final response = await _apiClient.dio.get(
        ApiConstants.decisionLogs,
        queryParameters: params,
      );

      final data = response.data;
      final List<dynamic> results = data['results'] ?? [];
      final logs = results
          .map((e) => DecisionLogModel.fromJson(e as Map<String, dynamic>))
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
        'error': e.response?.data?['error'] ?? 'Failed to load decision logs',
      };
    }
  }

  Future<Map<String, dynamic>> getDetail(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.decisionLogDetail(id));
      return {
        'success': true,
        'data': DecisionLogModel.fromJson(response.data as Map<String, dynamic>),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load decision detail',
      };
    }
  }

  Future<Map<String, dynamic>> undoDecision(String id) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.decisionLogUndo(id));
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to undo decision',
      };
    }
  }
}
