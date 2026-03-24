import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/triage_models.dart';

/// Repository for the pain triage workflow (v6.5 §24).
class TriageRepository {
  final ApiClient _apiClient;

  TriageRepository(this._apiClient);

  /// Start a triage flow from a pain event.
  Future<Map<String, dynamic>> startTriage({
    required String painEventId,
    required String activeSessionId,
    String? activeSetLogId,
  }) async {
    try {
      final body = <String, dynamic>{
        'pain_event_id': painEventId,
        'active_session_id': activeSessionId,
      };
      if (activeSetLogId != null) {
        body['active_set_log_id'] = activeSetLogId;
      }

      final response = await _apiClient.dio.post(
        ApiConstants.painTriageStart,
        data: body,
      );

      if (response.statusCode == 201) {
        final result = TriageStartResult.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'result': result};
      }
      return {'success': false, 'error': 'Failed to start triage'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? 'Failed to start triage',
      };
    }
  }

  /// Submit round 2 answers and get the remedy ladder.
  Future<Map<String, dynamic>> submitRound2({
    required String triageResponseId,
    required String loadSensitivity,
    required String romSensitivity,
    required String tempoSensitivity,
    bool supportHelps = false,
    String previousTrigger = '',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.painTriageRound2(triageResponseId),
        data: {
          'load_sensitivity': loadSensitivity,
          'rom_sensitivity': romSensitivity,
          'tempo_sensitivity': tempoSensitivity,
          'support_helps': supportHelps,
          'previous_trigger': previousTrigger,
        },
      );

      if (response.statusCode == 200) {
        final result = RemedyLadderResult.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'result': result};
      }
      return {'success': false, 'error': 'Failed to submit round 2'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? 'Failed to submit round 2',
      };
    }
  }

  /// Record an intervention step result.
  Future<Map<String, dynamic>> recordIntervention({
    required String triageResponseId,
    required int stepOrder,
    required bool applied,
    required String result,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.painTriageIntervention(triageResponseId),
        data: {
          'step_order': stepOrder,
          'applied': applied,
          'result': result,
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to record intervention'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? 'Failed to record intervention',
      };
    }
  }

  /// Finalize the triage with a proceed decision.
  Future<Map<String, dynamic>> finalizeTriage({
    required String triageResponseId,
    required String proceedDecision,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.painTriageFinalize(triageResponseId),
        data: {'proceed_decision': proceedDecision},
      );

      if (response.statusCode == 200) {
        final result = TriageFinalizeResult.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'result': result};
      }
      return {'success': false, 'error': 'Failed to finalize triage'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? 'Failed to finalize triage',
      };
    }
  }
}
