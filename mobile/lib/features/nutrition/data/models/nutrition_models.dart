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
    int? id,
    required String name,
    @Default('') String brand,
    @JsonKey(name: 'serving_size') @Default(1.0) double servingSize,
    @JsonKey(name: 'serving_unit') @Default('g') String servingUnit,
    @Default(0) int calories,
    @Default(0.0) double protein,
    @Default(0.0) double carbs,
    @Default(0.0) double fat,
    @Default(0.0) double fiber,
    @Default(0.0) double sugar,
    @Default(0.0) double sodium,
    @Default('') String barcode,
    @JsonKey(name: 'is_public') @Default(false) bool isPublic,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_email') String? createdByEmail,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _FoodItemModel;

  factory FoodItemModel.fromJson(Map<String, dynamic> json) =>
      _$FoodItemModelFromJson(json);
}

@freezed
class MealLogEntryModel with _$MealLogEntryModel {
  const factory MealLogEntryModel({
    required int id,
    @JsonKey(name: 'food_item') int? foodItem,
    @JsonKey(name: 'food_item_name') String? foodItemName,
    @JsonKey(name: 'food_item_brand') String? foodItemBrand,
    @JsonKey(name: 'custom_name') @Default('') String customName,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @Default(1.0) double quantity,
    @JsonKey(name: 'serving_unit') @Default('serving') String servingUnit,
    @Default(0) int calories,
    @Default(0.0) double protein,
    @Default(0.0) double carbs,
    @Default(0.0) double fat,
    @JsonKey(name: 'fat_mode') @Default('total_fat') String fatMode,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MealLogEntryModel;

  factory MealLogEntryModel.fromJson(Map<String, dynamic> json) =>
      _$MealLogEntryModelFromJson(json);
}

@freezed
class MealLogModel with _$MealLogModel {
  const MealLogModel._();

  const factory MealLogModel({
    required int id,
    int? trainee,
    required String date,
    @JsonKey(name: 'meal_number') required int mealNumber,
    @JsonKey(name: 'meal_name') @Default('') String mealName,
    @Default([]) List<MealLogEntryModel> entries,
    @JsonKey(name: 'total_calories') @Default(0) int totalCalories,
    @JsonKey(name: 'total_protein') @Default(0.0) double totalProtein,
    @JsonKey(name: 'total_carbs') @Default(0.0) double totalCarbs,
    @JsonKey(name: 'total_fat') @Default(0.0) double totalFat,
    @JsonKey(name: 'logged_at') String? loggedAt,
  }) = _MealLogModel;

  factory MealLogModel.fromJson(Map<String, dynamic> json) =>
      _$MealLogModelFromJson(json);

  String get displayName {
    if (mealName.isNotEmpty) return mealName;
    return 'Meal $mealNumber';
  }
}

@freezed
class MealLogSummaryModel with _$MealLogSummaryModel {
  const factory MealLogSummaryModel({
    required String date,
    @JsonKey(name: 'total_calories') @Default(0) int totalCalories,
    @JsonKey(name: 'total_protein') @Default(0.0) double totalProtein,
    @JsonKey(name: 'total_carbs') @Default(0.0) double totalCarbs,
    @JsonKey(name: 'total_fat') @Default(0.0) double totalFat,
    @JsonKey(name: 'meal_count') @Default(0) int mealCount,
    @JsonKey(name: 'entry_count') @Default(0) int entryCount,
  }) = _MealLogSummaryModel;

  factory MealLogSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$MealLogSummaryModelFromJson(json);
}

@freezed
class MacroPresetModel with _$MacroPresetModel {
  const MacroPresetModel._();

  const factory MacroPresetModel({
    required int id,
    required String name,
    @Default(2000) int calories,
    @Default(150) int protein,
    @Default(200) int carbs,
    @Default(70) int fat,
    @JsonKey(name: 'frequency_per_week') int? frequencyPerWeek,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MacroPresetModel;

  factory MacroPresetModel.fromJson(Map<String, dynamic> json) =>
      _$MacroPresetModelFromJson(json);

  /// Get frequency display text
  String get frequencyDisplay {
    if (frequencyPerWeek == null) return '';
    if (frequencyPerWeek == 7) return 'Daily';
    if (frequencyPerWeek == 1) return '1x/week';
    return '${frequencyPerWeek}x/week';
  }
}
