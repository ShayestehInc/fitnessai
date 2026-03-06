import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition_template_models.freezed.dart';
part 'nutrition_template_models.g.dart';

@freezed
class NutritionTemplateModel with _$NutritionTemplateModel {
  const factory NutritionTemplateModel({
    required int id,
    required String name,
    @JsonKey(name: 'template_type') required String templateType,
    @Default(1) int version,
    @JsonKey(name: 'is_system') @Default(false) bool isSystem,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_email') String? createdByEmail,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _NutritionTemplateModel;

  factory NutritionTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$NutritionTemplateModelFromJson(json);
}

@freezed
class NutritionTemplateAssignmentModel with _$NutritionTemplateAssignmentModel {
  const factory NutritionTemplateAssignmentModel({
    required int id,
    required int trainee,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    required int template,
    @JsonKey(name: 'template_name') required String templateName,
    @JsonKey(name: 'template_type') required String templateType,
    @Default({}) Map<String, dynamic> parameters,
    @JsonKey(name: 'day_type_schedule')
    @Default({})
    Map<String, dynamic> dayTypeSchedule,
    @JsonKey(name: 'fat_mode') @Default('total_fat') String fatMode,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'activated_at') String? activatedAt,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _NutritionTemplateAssignmentModel;

  factory NutritionTemplateAssignmentModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$NutritionTemplateAssignmentModelFromJson(json);
}

@freezed
class NutritionDayPlanModel with _$NutritionDayPlanModel {
  const NutritionDayPlanModel._();

  const factory NutritionDayPlanModel({
    required int id,
    required int trainee,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    required String date,
    @JsonKey(name: 'day_type') required String dayType,
    @JsonKey(name: 'day_type_display') String? dayTypeDisplay,
    @JsonKey(name: 'template_snapshot')
    @Default({})
    Map<String, dynamic> templateSnapshot,
    @JsonKey(name: 'total_protein') @Default(0) int totalProtein,
    @JsonKey(name: 'total_carbs') @Default(0) int totalCarbs,
    @JsonKey(name: 'total_fat') @Default(0) int totalFat,
    @JsonKey(name: 'total_calories') @Default(0) int totalCalories,
    @Default([]) List<MealPlanModel> meals,
    @JsonKey(name: 'fat_mode') @Default('total_fat') String fatMode,
    @JsonKey(name: 'is_overridden') @Default(false) bool isOverridden,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _NutritionDayPlanModel;

  factory NutritionDayPlanModel.fromJson(Map<String, dynamic> json) =>
      _$NutritionDayPlanModelFromJson(json);

  String get templateName =>
      templateSnapshot['template_name'] as String? ?? 'Unknown';

  String get templateType =>
      templateSnapshot['template_type'] as String? ?? 'legacy';
}

@freezed
class MealPlanModel with _$MealPlanModel {
  const factory MealPlanModel({
    @JsonKey(name: 'meal_number') @Default(1) int mealNumber,
    @Default('Meal') String name,
    @Default(0) int protein,
    @Default(0) int carbs,
    @Default(0) int fat,
    @Default(0) int calories,
  }) = _MealPlanModel;

  factory MealPlanModel.fromJson(Map<String, dynamic> json) =>
      _$MealPlanModelFromJson(json);
}
