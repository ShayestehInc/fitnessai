import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/training_plan_models.dart';

class TrainingPlanRepository {
  final ApiClient _apiClient;

  TrainingPlanRepository(this._apiClient);

  /// Lists training plans with optional status filter and pagination.
  Future<Map<String, dynamic>> listPlans({
    String? status,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      final response = await _apiClient.dio.get(
        ApiConstants.trainingPlans,
        queryParameters: queryParams,
      );
      final data = response.data;
      final List<dynamic> results =
          data is Map ? (data['results'] ?? []) : (data as List);
      final plans = results
          .map((e) =>
              TrainingPlanModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': plans,
        'count': data is Map ? (data['count'] ?? plans.length) : plans.length,
        'next': data is Map ? data['next'] : null,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to load training plans',
      };
    }
  }

  /// Fetches a single training plan with all weeks, sessions, and slots.
  Future<Map<String, dynamic>> getPlanDetail(int planId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainingPlanDetail(planId),
      );
      final plan = TrainingPlanModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': plan,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to load plan details',
      };
    }
  }

  /// Creates a new training plan.
  Future<Map<String, dynamic>> createPlan({
    required String goal,
    int? splitTemplateId,
  }) async {
    try {
      final body = <String, dynamic>{'goal': goal};
      if (splitTemplateId != null) {
        body['split_template'] = splitTemplateId;
      }
      final response = await _apiClient.dio.post(
        ApiConstants.trainingPlans,
        data: body,
      );
      final plan = TrainingPlanModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': plan,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to create plan',
      };
    }
  }

  /// Updates an existing training plan.
  Future<Map<String, dynamic>> updatePlan(
    int planId, {
    String? goal,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (goal != null) body['goal'] = goal;
      if (status != null) body['status'] = status;
      final response = await _apiClient.dio.patch(
        ApiConstants.trainingPlanDetail(planId),
        data: body,
      );
      final plan = TrainingPlanModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': plan,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to update plan',
      };
    }
  }

  /// Fetches a single session with its slots.
  Future<Map<String, dynamic>> getSessionDetail(int sessionId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.planSessionDetail(sessionId),
      );
      final session = PlanSessionModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': session,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to load session details',
      };
    }
  }

  /// Lists available split templates.
  Future<Map<String, dynamic>> listSplitTemplates() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.splitTemplates,
      );
      final data = response.data;
      final List<dynamic> results =
          data is Map ? (data['results'] ?? []) : (data as List);
      final templates = results
          .map((e) =>
              SplitTemplateModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': templates,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to load split templates',
      };
    }
  }

  /// Lists available set structure modalities.
  Future<Map<String, dynamic>> listModalities() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.modalities,
      );
      final data = response.data;
      final List<dynamic> results =
          data is Map ? (data['results'] ?? []) : (data as List);
      final modalities = results
          .map((e) =>
              ModalityModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': modalities,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to load modalities',
      };
    }
  }

  /// Updates a plan slot (e.g., swap exercise, change sets/reps).
  Future<Map<String, dynamic>> updateSlot(
    int slotId, {
    int? exerciseId,
    int? sets,
    int? repsMin,
    int? repsMax,
    int? restSeconds,
    int? modalityId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (exerciseId != null) body['exercise'] = exerciseId;
      if (sets != null) body['sets'] = sets;
      if (repsMin != null) body['reps_min'] = repsMin;
      if (repsMax != null) body['reps_max'] = repsMax;
      if (restSeconds != null) body['rest_seconds'] = restSeconds;
      if (modalityId != null) body['set_structure_modality'] = modalityId;
      final response = await _apiClient.dio.patch(
        ApiConstants.planSlotDetail(slotId),
        data: body,
      );
      final slot = PlanSlotModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {
        'success': true,
        'data': slot,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to update slot',
      };
    }
  }
}
