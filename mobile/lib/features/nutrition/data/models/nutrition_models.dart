import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition_models.freezed.dart';
part 'nutrition_models.g.dart';

@freezed
class NutritionGoalModel with _$NutritionGoalModel {
  const factory NutritionGoalModel({
    int? id,
    int? trainee,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    @JsonKey(name: 'protein_goal') @Default(0) int proteinGoal,
    @JsonKey(name: 'carbs_goal') @Default(0) int carbsGoal,
    @JsonKey(name: 'fat_goal') @Default(0) int fatGoal,
    @JsonKey(name: 'calories_goal') @Default(0) int caloriesGoal,
    @JsonKey(name: 'per_meal_protein') @Default(0) int perMealProtein,
    @JsonKey(name: 'per_meal_carbs') @Default(0) int perMealCarbs,
    @JsonKey(name: 'per_meal_fat') @Default(0) int perMealFat,
    @JsonKey(name: 'is_trainer_adjusted') @Default(false) bool isTrainerAdjusted,
  }) = _NutritionGoalModel;

  factory NutritionGoalModel.fromJson(Map<String, dynamic> json) =>
      _$NutritionGoalModelFromJson(json);
}

@freezed
class DailyNutritionSummary with _$DailyNutritionSummary {
  const factory DailyNutritionSummary({
    required String date,
    required MacroSummary goals,
    required MacroSummary consumed,
    required MacroSummary remaining,
    @Default([]) List<MealEntry> meals,
    @JsonKey(name: 'per_meal_targets') required PerMealTargets perMealTargets,
  }) = _DailyNutritionSummary;

  factory DailyNutritionSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyNutritionSummaryFromJson(json);
}

@freezed
class MacroSummary with _$MacroSummary {
  const factory MacroSummary({
    @Default(0) int protein,
    @Default(0) int carbs,
    @Default(0) int fat,
    @Default(0) int calories,
  }) = _MacroSummary;

  factory MacroSummary.fromJson(Map<String, dynamic> json) =>
      _$MacroSummaryFromJson(json);
}

@freezed
class PerMealTargets with _$PerMealTargets {
  const factory PerMealTargets({
    @Default(0) int protein,
    @Default(0) int carbs,
    @Default(0) int fat,
  }) = _PerMealTargets;

  factory PerMealTargets.fromJson(Map<String, dynamic> json) =>
      _$PerMealTargetsFromJson(json);
}

@freezed
class MealEntry with _$MealEntry {
  const factory MealEntry({
    required String name,
    @Default(0) int protein,
    @Default(0) int carbs,
    @Default(0) int fat,
    @Default(0) int calories,
    String? timestamp,
  }) = _MealEntry;

  factory MealEntry.fromJson(Map<String, dynamic> json) =>
      _$MealEntryFromJson(json);
}

@freezed
class WeightCheckInModel with _$WeightCheckInModel {
  const factory WeightCheckInModel({
    int? id,
    int? trainee,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    required String date,
    @JsonKey(name: 'weight_kg') required double weightKg,
    @Default('') String notes,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _WeightCheckInModel;

  factory WeightCheckInModel.fromJson(Map<String, dynamic> json) =>
      _$WeightCheckInModelFromJson(json);
}

@freezed
class FoodItemModel with _$FoodItemModel {
  const factory FoodItemModel({
    String? id,
    required String name,
    @JsonKey(name: 'serving_size') String? servingSize,
    @Default(0) int protein,
    @Default(0) int carbs,
    @Default(0) int fat,
    @Default(0) int calories,
    String? brand,
  }) = _FoodItemModel;

  factory FoodItemModel.fromJson(Map<String, dynamic> json) =>
      _$FoodItemModelFromJson(json);
}
