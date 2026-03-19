import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/builder_models.dart';
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
  Future<Map<String, dynamic>> getPlanDetail(String planId) async {
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
    String planId, {
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
  Future<Map<String, dynamic>> getSessionDetail(String sessionId) async {
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

  /// Quick Build: send brief, get completed plan + explanations.
  Future<Map<String, dynamic>> quickBuild(BuilderBrief brief) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.quickBuild,
        data: brief.toJson(),
      );
      final result = QuickBuildResult.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {'success': true, 'data': result};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Quick build failed',
      };
    }
  }

  /// Advanced Builder: start a builder session with brief.
  Future<Map<String, dynamic>> builderStart(BuilderBrief brief) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.builderStart,
        data: brief.toJson(),
      );
      final result = BuilderStepResult.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {'success': true, 'data': result};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Builder start failed',
      };
    }
  }

  /// Advanced Builder: advance to the next step with optional override.
  Future<Map<String, dynamic>> builderAdvance(
    String planId, {
    Map<String, dynamic>? override,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (override != null) body['override'] = override;
      final response = await _apiClient.dio.post(
        ApiConstants.builderAdvance(planId),
        data: body,
      );
      final result = BuilderStepResult.fromJson(
        response.data as Map<String, dynamic>,
      );
      return {'success': true, 'data': result};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Builder advance failed',
      };
    }
  }

  /// Advanced Builder: get current builder state.
  Future<Map<String, dynamic>> builderGetState(String planId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.builderState(planId),
      );
      return {
        'success': true,
        'data': response.data as Map<String, dynamic>,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to get builder state',
      };
    }
  }

  /// Convert a TrainingPlan to a legacy Program (optionally assign to trainee).
  Future<Map<String, dynamic>> convertToProgram(
    String planId, {
    int? traineeId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (traineeId != null) body['trainee_id'] = traineeId;
      final response = await _apiClient.dio.post(
        ApiConstants.convertToProgram(planId),
        data: body,
      );
      return {
        'success': true,
        'data': response.data as Map<String, dynamic>,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ??
            e.response?.data?['detail'] ??
            'Failed to convert plan',
      };
    }
  }

  /// Updates a plan slot (e.g., swap exercise, change sets/reps).
  Future<Map<String, dynamic>> updateSlot(
    String slotId, {
    int? exerciseId,
    int? sets,
    int? repsMin,
    int? repsMax,
    int? restSeconds,
    String? modalityId,
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
