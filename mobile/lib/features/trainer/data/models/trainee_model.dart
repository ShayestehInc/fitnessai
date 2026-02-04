import 'package:freezed_annotation/freezed_annotation.dart';

part 'trainee_model.freezed.dart';
part 'trainee_model.g.dart';

@freezed
class TraineeModel with _$TraineeModel {
  const TraineeModel._();

  const factory TraineeModel({
    required int id,
    required String email,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'profile_complete') @Default(false) bool profileComplete,
    @JsonKey(name: 'last_activity') String? lastActivity,
    @JsonKey(name: 'current_program') ProgramSummary? currentProgram,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _TraineeModel;

  factory TraineeModel.fromJson(Map<String, dynamic> json) =>
      _$TraineeModelFromJson(json);

  String get displayName {
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isEmpty ? email.split('@').first : name;
  }
}

@freezed
class ProgramSummary with _$ProgramSummary {
  const factory ProgramSummary({
    required int id,
    required String name,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _ProgramSummary;

  factory ProgramSummary.fromJson(Map<String, dynamic> json) =>
      _$ProgramSummaryFromJson(json);
}

@freezed
class TraineeDetailModel with _$TraineeDetailModel {
  const factory TraineeDetailModel({
    required int id,
    required String email,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
    TraineeProfile? profile,
    @JsonKey(name: 'nutrition_goal') NutritionGoalSummary? nutritionGoal,
    @Default([]) List<ProgramSummary> programs,
    @JsonKey(name: 'recent_activity') @Default([]) List<ActivitySummary> recentActivity,
  }) = _TraineeDetailModel;

  factory TraineeDetailModel.fromJson(Map<String, dynamic> json) =>
      _$TraineeDetailModelFromJson(json);
}

@freezed
class TraineeProfile with _$TraineeProfile {
  const factory TraineeProfile({
    String? sex,
    int? age,
    @JsonKey(name: 'height_cm') double? heightCm,
    @JsonKey(name: 'weight_kg') double? weightKg,
    @JsonKey(name: 'activity_level') String? activityLevel,
    String? goal,
    @JsonKey(name: 'diet_type') String? dietType,
    @JsonKey(name: 'meals_per_day') int? mealsPerDay,
    @JsonKey(name: 'onboarding_completed') @Default(false) bool onboardingCompleted,
  }) = _TraineeProfile;

  factory TraineeProfile.fromJson(Map<String, dynamic> json) =>
      _$TraineeProfileFromJson(json);
}

@freezed
class NutritionGoalSummary with _$NutritionGoalSummary {
  const factory NutritionGoalSummary({
    @JsonKey(name: 'protein_goal') @Default(0) int proteinGoal,
    @JsonKey(name: 'carbs_goal') @Default(0) int carbsGoal,
    @JsonKey(name: 'fat_goal') @Default(0) int fatGoal,
    @JsonKey(name: 'calories_goal') @Default(0) int caloriesGoal,
    @JsonKey(name: 'is_trainer_adjusted') @Default(false) bool isTrainerAdjusted,
  }) = _NutritionGoalSummary;

  factory NutritionGoalSummary.fromJson(Map<String, dynamic> json) =>
      _$NutritionGoalSummaryFromJson(json);
}

@freezed
class ActivitySummary with _$ActivitySummary {
  const factory ActivitySummary({
    required String date,
    @JsonKey(name: 'logged_food') @Default(false) bool loggedFood,
    @JsonKey(name: 'logged_workout') @Default(false) bool loggedWorkout,
    @JsonKey(name: 'calories_consumed') @Default(0) int caloriesConsumed,
    @JsonKey(name: 'protein_consumed') @Default(0) int proteinConsumed,
    @JsonKey(name: 'hit_protein_goal') @Default(false) bool hitProteinGoal,
    @JsonKey(name: 'workouts_completed') @Default(0) int workoutsCompleted,
    @JsonKey(name: 'total_sets') @Default(0) int totalSets,
    @JsonKey(name: 'total_volume') @Default(0.0) double totalVolume,
  }) = _ActivitySummary;

  factory ActivitySummary.fromJson(Map<String, dynamic> json) =>
      _$ActivitySummaryFromJson(json);
}
