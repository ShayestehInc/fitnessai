import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/feedback_models.dart';

class FeedbackRepository {
  final ApiClient _apiClient;

  FeedbackRepository(this._apiClient);

  /// Submit session feedback for a given session.
  Future<Map<String, dynamic>> submitFeedback({
    required int sessionPk,
    required String completionState,
    required Map<String, int> ratings,
    List<String> frictionReasons = const [],
    bool recoveryConcern = false,
    List<String> winReasons = const [],
    String sessionVolumePerception = '',
    String requestedAction = '',
    String notes = '',
    List<Map<String, dynamic>> painEvents = const [],
  }) async {
    try {
      final body = <String, dynamic>{
        'completion_state': completionState,
        'ratings': ratings,
        'friction_reasons': frictionReasons,
        'recovery_concern': recoveryConcern,
        'win_reasons': winReasons,
        'session_volume_perception': sessionVolumePerception,
        'requested_action': requestedAction,
        'notes': notes,
        'pain_events': painEvents,
      };

      final response = await _apiClient.dio.post(
        ApiConstants.sessionFeedbackSubmit('$sessionPk'),
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = FeedbackSubmitResult.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'result': result};
      }

      return {'success': false, 'error': 'Failed to submit feedback'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to submit session feedback',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// List all feedback entries (paginated).
  Future<Map<String, dynamic>> listFeedback({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.sessionFeedback,
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is List
            ? data as List<dynamic>
            : (data is Map && data.containsKey('results'))
                ? data['results'] as List<dynamic>
                : [];

        final feedbackList = results
            .map((json) =>
                SessionFeedbackModel.fromJson(json as Map<String, dynamic>))
            .toList();

        final hasNext = data is Map && data['next'] != null;

        return {
          'success': true,
          'feedback': feedbackList,
          'has_next': hasNext,
        };
      }

      return {'success': false, 'error': 'Failed to fetch feedback'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to fetch feedback list',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get feedback for a specific session.
  Future<Map<String, dynamic>> getFeedbackForSession(int sessionPk) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.sessionFeedbackForSession('$sessionPk'),
      );

      if (response.statusCode == 200) {
        final feedback = SessionFeedbackModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'feedback': feedback};
      }

      return {'success': false, 'error': 'Failed to fetch session feedback'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'No feedback found for this session'};
      }
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to fetch session feedback',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Log a standalone pain event.
  Future<Map<String, dynamic>> logPainEvent({
    required String bodyRegion,
    required int painScore,
    String? side,
    String? sensationType,
    String? onsetPhase,
    String? warmupEffect,
    int? exerciseId,
    int? activeSessionId,
    String notes = '',
  }) async {
    try {
      final body = <String, dynamic>{
        'body_region': bodyRegion,
        'pain_score': painScore,
        'notes': notes,
      };

      if (side != null) body['side'] = side;
      if (sensationType != null) body['sensation_type'] = sensationType;
      if (onsetPhase != null) body['onset_phase'] = onsetPhase;
      if (warmupEffect != null) body['warmup_effect'] = warmupEffect;
      if (exerciseId != null) body['exercise_id'] = exerciseId;
      if (activeSessionId != null) {
        body['active_session_id'] = activeSessionId;
      }

      final response = await _apiClient.dio.post(
        ApiConstants.painEventLog,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final painEvent = PainEventModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'pain_event': painEvent};
      }

      return {'success': false, 'error': 'Failed to log pain event'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to log pain event',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// List pain events with optional body region filter.
  Future<Map<String, dynamic>> listPainEvents({String? bodyRegion}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (bodyRegion != null) {
        queryParams['body_region'] = bodyRegion;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.painEvents,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is List
            ? data as List<dynamic>
            : (data is Map && data.containsKey('results'))
                ? data['results'] as List<dynamic>
                : [];

        final events = results
            .map((json) =>
                PainEventModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return {'success': true, 'pain_events': events};
      }

      return {'success': false, 'error': 'Failed to fetch pain events'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to fetch pain events',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
