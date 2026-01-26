import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_log_model.freezed.dart';
part 'parsed_log_model.g.dart';

@freezed
class ParsedLogModel with _$ParsedLogModel {
  const factory ParsedLogModel({
    @JsonKey(name: 'nutrition') required NutritionData nutrition,
    @JsonKey(name: 'workout') required WorkoutData workout,
    required double confidence,
    @JsonKey(name: 'needs_clarification') required bool needsClarification,
    @JsonKey(name: 'clarification_question') String? clarificationQuestion,
  }) = _ParsedLogModel;

  factory ParsedLogModel.fromJson(Map<String, dynamic> json) =>
      _$ParsedLogModelFromJson(json);
}

@freezed
class NutritionData with _$NutritionData {
  const factory NutritionData({
    @Default([]) List<MealData> meals,
  }) = _NutritionData;

  factory NutritionData.fromJson(Map<String, dynamic> json) =>
      _$NutritionDataFromJson(json);
}

@freezed
class MealData with _$MealData {
  const factory MealData({
    required String name,
    @Default(0.0) double protein,
    @Default(0.0) double carbs,
    @Default(0.0) double fat,
    @Default(0.0) double calories,
    String? timestamp,
  }) = _MealData;

  factory MealData.fromJson(Map<String, dynamic> json) =>
      _$MealDataFromJson(json);
}

@freezed
class WorkoutData with _$WorkoutData {
  const factory WorkoutData({
    @Default([]) List<ExerciseData> exercises,
  }) = _WorkoutData;

  factory WorkoutData.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDataFromJson(json);
}

@freezed
class ExerciseData with _$ExerciseData {
  const factory ExerciseData({
    @JsonKey(name: 'exercise_name') required String exerciseName,
    required int sets,
    required dynamic reps, // Can be int or String like "8-10"
    required double weight,
    @Default('lbs') String unit,
    String? timestamp,
  }) = _ExerciseData;

  factory ExerciseData.fromJson(Map<String, dynamic> json) =>
      _$ExerciseDataFromJson(json);
}
