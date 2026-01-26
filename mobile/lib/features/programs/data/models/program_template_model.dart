import 'package:freezed_annotation/freezed_annotation.dart';

part 'program_template_model.freezed.dart';
part 'program_template_model.g.dart';

@freezed
class ProgramTemplateModel with _$ProgramTemplateModel {
  const factory ProgramTemplateModel({
    required int id,
    required String name,
    @Default('') String description,
    @JsonKey(name: 'duration_weeks') required int durationWeeks,
    @JsonKey(name: 'schedule_template') @Default({}) Map<String, dynamic> scheduleTemplate,
    @JsonKey(name: 'nutrition_template') @Default({}) Map<String, dynamic> nutritionTemplate,
    @JsonKey(name: 'difficulty_level') @Default('intermediate') String difficultyLevel,
    @JsonKey(name: 'goal_type') @Default('build_muscle') String goalType,
    @JsonKey(name: 'is_public') @Default(false) bool isPublic,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_email') String? createdByEmail,
    @JsonKey(name: 'times_used') @Default(0) int timesUsed,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _ProgramTemplateModel;

  factory ProgramTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramTemplateModelFromJson(json);
}

@freezed
class ProgramWeekModel with _$ProgramWeekModel {
  const factory ProgramWeekModel({
    required int id,
    required int program,
    @JsonKey(name: 'week_number') required int weekNumber,
    @JsonKey(name: 'workout_schedule') @Default({}) Map<String, dynamic> workoutSchedule,
    @JsonKey(name: 'nutrition_adjustments') @Default({}) Map<String, dynamic> nutritionAdjustments,
    @JsonKey(name: 'intensity_modifier') @Default(1.0) double intensityModifier,
    @JsonKey(name: 'volume_modifier') @Default(1.0) double volumeModifier,
    @JsonKey(name: 'is_deload') @Default(false) bool isDeload,
    @Default('') String notes,
  }) = _ProgramWeekModel;

  factory ProgramWeekModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramWeekModelFromJson(json);
}

@freezed
class WeeklyNutritionModel with _$WeeklyNutritionModel {
  const factory WeeklyNutritionModel({
    required int id,
    required int program,
    @JsonKey(name: 'week_number') required int weekNumber,
    @JsonKey(name: 'protein_goal') @Default(0) int proteinGoal,
    @JsonKey(name: 'carbs_goal') @Default(0) int carbsGoal,
    @JsonKey(name: 'fat_goal') @Default(0) int fatGoal,
    @JsonKey(name: 'calories_goal') @Default(0) int caloriesGoal,
    @JsonKey(name: 'training_day_carbs_modifier') @Default(1.0) double trainingDayCarbsModifier,
    @JsonKey(name: 'rest_day_carbs_modifier') @Default(0.8) double restDayCarbsModifier,
    @Default('') String notes,
  }) = _WeeklyNutritionModel;

  factory WeeklyNutritionModel.fromJson(Map<String, dynamic> json) =>
      _$WeeklyNutritionModelFromJson(json);
}
