import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/nutrition_template_models.dart';

class NutritionTemplateRepository {
  final ApiClient _apiClient;

  const NutritionTemplateRepository(this._apiClient);

  /// List available nutrition templates.
  Future<Map<String, dynamic>> getTemplates() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.nutritionTemplates,
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final templates = data
            .map((e) =>
                NutritionTemplateModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'templates': templates};
      }

      return {'success': false, 'error': 'Failed to load templates'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to load nutrition templates',
      };
    }
  }

  /// Get the active template assignment for a trainee.
  Future<Map<String, dynamic>> getActiveAssignment({int? traineeId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (traineeId != null) {
        queryParams['trainee_id'] = traineeId;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.nutritionTemplateAssignments,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        // Find the active assignment
        final activeList = data
            .map((e) => NutritionTemplateAssignmentModel.fromJson(
                e as Map<String, dynamic>))
            .where((a) => a.isActive)
            .toList();

        if (activeList.isEmpty) {
          return {'success': true, 'assignment': null};
        }
        return {'success': true, 'assignment': activeList.first};
      }

      return {'success': false, 'error': 'Failed to load assignment'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to load template assignment',
      };
    }
  }

  /// Assign a template to a trainee (trainer action).
  Future<Map<String, dynamic>> createAssignment({
    required int traineeId,
    required int templateId,
    Map<String, dynamic> parameters = const {},
    Map<String, dynamic> dayTypeSchedule = const {},
    String fatMode = 'total_fat',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.nutritionTemplateAssignments,
        data: {
          'trainee_id': traineeId,
          'template_id': templateId,
          'parameters': parameters,
          'day_type_schedule': dayTypeSchedule,
          'fat_mode': fatMode,
        },
      );

      if (response.statusCode == 201) {
        final assignment = NutritionTemplateAssignmentModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'assignment': assignment};
      }

      return {'success': false, 'error': 'Failed to create assignment'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to assign nutrition template',
      };
    }
  }

  /// Update an existing assignment.
  Future<Map<String, dynamic>> updateAssignment({
    required int id,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? dayTypeSchedule,
    String? fatMode,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (parameters != null) data['parameters'] = parameters;
      if (dayTypeSchedule != null) data['day_type_schedule'] = dayTypeSchedule;
      if (fatMode != null) data['fat_mode'] = fatMode;

      final response = await _apiClient.dio.put(
        ApiConstants.nutritionTemplateAssignmentDetail(id),
        data: data,
      );

      if (response.statusCode == 200) {
        final assignment = NutritionTemplateAssignmentModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'assignment': assignment};
      }

      return {'success': false, 'error': 'Failed to update assignment'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update assignment',
      };
    }
  }

  /// Get the day plan for a specific date.
  Future<Map<String, dynamic>> getDayPlan(String date,
      {int? traineeId}) async {
    try {
      final queryParams = <String, dynamic>{'date': date};
      if (traineeId != null) queryParams['trainee_id'] = traineeId;

      final response = await _apiClient.dio.get(
        ApiConstants.nutritionDayPlans,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final plan = NutritionDayPlanModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'plan': plan};
      }

      return {'success': true, 'plan': null};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': true, 'plan': null};
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load day plan',
      };
    }
  }

  /// Get a week of day plans starting from a date.
  Future<Map<String, dynamic>> getWeekPlans(String startDate,
      {int? traineeId}) async {
    try {
      final queryParams = <String, dynamic>{'start': startDate};
      if (traineeId != null) queryParams['trainee_id'] = traineeId;

      final response = await _apiClient.dio.get(
        ApiConstants.nutritionDayPlansWeek,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final plans = data
            .map((e) =>
                NutritionDayPlanModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'plans': plans};
      }

      return {'success': false, 'error': 'Failed to load week plans'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load week plans',
      };
    }
  }
}
