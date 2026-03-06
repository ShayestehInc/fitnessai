import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/nutrition_template_models.dart';

class NutritionTemplateRepository {
  final ApiClient _apiClient;

  const NutritionTemplateRepository(this._apiClient);

  /// List available nutrition templates.
  Future<List<NutritionTemplateModel>> getTemplates() async {
    final response = await _apiClient.dio.get(
      ApiConstants.nutritionTemplates,
    );

    final data = response.data as List<dynamic>;
    return data
        .map(
            (e) => NutritionTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get the active template assignment for a trainee.
  Future<NutritionTemplateAssignmentModel?> getActiveAssignment(
      {int? traineeId}) async {
    final queryParams = <String, dynamic>{};
    if (traineeId != null) {
      queryParams['trainee_id'] = traineeId;
    }

    final response = await _apiClient.dio.get(
      ApiConstants.nutritionTemplateAssignments,
      queryParameters: queryParams,
    );

    final data = response.data as List<dynamic>;
    final activeList = data
        .map((e) => NutritionTemplateAssignmentModel.fromJson(
            e as Map<String, dynamic>))
        .where((a) => a.isActive)
        .toList();

    if (activeList.isEmpty) {
      return null;
    }
    return activeList.first;
  }

  /// Assign a template to a trainee (trainer action).
  Future<NutritionTemplateAssignmentModel> createAssignment({
    required int traineeId,
    required int templateId,
    Map<String, dynamic> parameters = const {},
    Map<String, dynamic> dayTypeSchedule = const {},
    String fatMode = 'total_fat',
  }) async {
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

    return NutritionTemplateAssignmentModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Update an existing assignment.
  Future<NutritionTemplateAssignmentModel> updateAssignment({
    required int id,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? dayTypeSchedule,
    String? fatMode,
  }) async {
    final data = <String, dynamic>{};
    if (parameters != null) data['parameters'] = parameters;
    if (dayTypeSchedule != null) data['day_type_schedule'] = dayTypeSchedule;
    if (fatMode != null) data['fat_mode'] = fatMode;

    final response = await _apiClient.dio.put(
      ApiConstants.nutritionTemplateAssignmentDetail(id),
      data: data,
    );

    return NutritionTemplateAssignmentModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Get the day plan for a specific date.
  /// Returns null if no plan is configured (404).
  Future<NutritionDayPlanModel?> getDayPlan(String date,
      {int? traineeId}) async {
    try {
      final queryParams = <String, dynamic>{'date': date};
      if (traineeId != null) queryParams['trainee_id'] = traineeId;

      final response = await _apiClient.dio.get(
        ApiConstants.nutritionDayPlans,
        queryParameters: queryParams,
      );

      return NutritionDayPlanModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Get a week of day plans starting from a date.
  Future<List<NutritionDayPlanModel>> getWeekPlans(String startDate,
      {int? traineeId}) async {
    final queryParams = <String, dynamic>{'start': startDate};
    if (traineeId != null) queryParams['trainee_id'] = traineeId;

    final response = await _apiClient.dio.get(
      ApiConstants.nutritionDayPlansWeek,
      queryParameters: queryParams,
    );

    final data = response.data as List<dynamic>;
    return data
        .map(
            (e) => NutritionDayPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
