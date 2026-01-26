import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

/// Enum values for profile fields
class ProfileEnums {
  static const List<String> sexOptions = ['male', 'female'];

  static const List<String> activityLevels = [
    'sedentary',
    'lightly_active',
    'moderately_active',
    'very_active',
    'extremely_active',
  ];

  static const Map<String, String> activityLevelLabels = {
    'sedentary': 'Sedentary',
    'lightly_active': 'Lightly Active',
    'moderately_active': 'Moderately Active',
    'very_active': 'Very Active',
    'extremely_active': 'Extremely Active',
  };

  static const Map<String, String> activityLevelDescriptions = {
    'sedentary': 'Little to no exercise',
    'lightly_active': 'Light exercise 1-3 days/week',
    'moderately_active': 'Moderate exercise 3-5 days/week',
    'very_active': 'Hard exercise 6-7 days/week',
    'extremely_active': 'Very hard exercise, physical job',
  };

  static const List<String> goals = [
    'build_muscle',
    'fat_loss',
    'recomp',
  ];

  static const Map<String, String> goalLabels = {
    'build_muscle': 'Build Muscle',
    'fat_loss': 'Fat Loss',
    'recomp': 'Recomp',
  };

  static const Map<String, String> goalDescriptions = {
    'build_muscle': 'Gain muscle mass with a calorie surplus',
    'fat_loss': 'Lose body fat with a calorie deficit',
    'recomp': 'Build muscle while losing fat',
  };

  static const List<String> dietTypes = [
    'low_carb',
    'balanced',
    'high_carb',
  ];

  static const Map<String, String> dietTypeLabels = {
    'low_carb': 'Low Carb',
    'balanced': 'Balanced',
    'high_carb': 'High Carb',
  };

  static const List<String> weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const Map<String, String> weekDayLabels = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };
}

@freezed
class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    int? id,
    int? user,
    @JsonKey(name: 'user_email') String? userEmail,
    String? sex,
    int? age,
    @JsonKey(name: 'height_cm') double? heightCm,
    @JsonKey(name: 'weight_kg') double? weightKg,
    @JsonKey(name: 'activity_level') @Default('moderately_active') String activityLevel,
    @Default('build_muscle') String goal,
    @JsonKey(name: 'check_in_days') @Default([]) List<String> checkInDays,
    @JsonKey(name: 'diet_type') @Default('balanced') String dietType,
    @JsonKey(name: 'meals_per_day') @Default(4) int mealsPerDay,
    @JsonKey(name: 'onboarding_completed') @Default(false) bool onboardingCompleted,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}

@freezed
class NutritionGoalsModel with _$NutritionGoalsModel {
  const factory NutritionGoalsModel({
    @JsonKey(name: 'protein_goal') @Default(0) int proteinGoal,
    @JsonKey(name: 'carbs_goal') @Default(0) int carbsGoal,
    @JsonKey(name: 'fat_goal') @Default(0) int fatGoal,
    @JsonKey(name: 'calories_goal') @Default(0) int caloriesGoal,
    @JsonKey(name: 'per_meal_protein') @Default(0) int perMealProtein,
    @JsonKey(name: 'per_meal_carbs') @Default(0) int perMealCarbs,
    @JsonKey(name: 'per_meal_fat') @Default(0) int perMealFat,
  }) = _NutritionGoalsModel;

  factory NutritionGoalsModel.fromJson(Map<String, dynamic> json) =>
      _$NutritionGoalsModelFromJson(json);
}

@freezed
class OnboardingCompleteResponse with _$OnboardingCompleteResponse {
  const factory OnboardingCompleteResponse({
    required UserProfileModel profile,
    @JsonKey(name: 'nutrition_goals') required NutritionGoalsModel nutritionGoals,
  }) = _OnboardingCompleteResponse;

  factory OnboardingCompleteResponse.fromJson(Map<String, dynamic> json) =>
      _$OnboardingCompleteResponseFromJson(json);
}
