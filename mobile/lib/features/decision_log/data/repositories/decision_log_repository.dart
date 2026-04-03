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
      final List<dynamic> results;
      int count = 0;
      String? next;
      String? previous;

      if (data is List) {
        // Non-paginated response (raw list)
        results = data;
        count = data.length;
      } else if (data is Map<String, dynamic>) {
        results = data['results'] as List<dynamic>? ?? [];
        count = (data['count'] as num?)?.toInt() ?? results.length;
        next = data['next'] as String?;
        previous = data['previous'] as String?;
      } else {
        throw FormatException(
          'Unexpected response type: ${data.runtimeType}',
        );
      }

      final logs = results
          .map((e) => DecisionLogModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'success': true,
        'data': logs,
        'count': count,
        'next': next,
        'previous': previous,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load decision logs',
      };
    } on Exception catch (e) {
      return {
        'success': false,
        'error': e.toString(),
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
    } on Exception catch (e) {
      return {
        'success': false,
        'error': e.toString(),
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
    } on Exception catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
