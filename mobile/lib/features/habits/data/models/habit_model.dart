import 'package:json_annotation/json_annotation.dart';

part 'habit_model.g.dart';

@JsonSerializable()
class HabitModel {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String frequency;
  @JsonKey(name: 'custom_days')
  final List<String> customDays;
  @JsonKey(name: 'is_active')
  final bool isActive;

  const HabitModel({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'check_circle',
    this.frequency = 'daily',
    this.customDays = const [],
    this.isActive = true,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) =>
      _$HabitModelFromJson(json);

  Map<String, dynamic> toJson() => _$HabitModelToJson(this);
}

@JsonSerializable()
class HabitStreakModel {
  @JsonKey(name: 'habit_id')
  final int habitId;
  @JsonKey(name: 'habit_name')
  final String habitName;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'completion_rate_30d')
  final double completionRate30d;

  const HabitStreakModel({
    required this.habitId,
    required this.habitName,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completionRate30d = 0.0,
  });

  factory HabitStreakModel.fromJson(Map<String, dynamic> json) =>
      _$HabitStreakModelFromJson(json);

  Map<String, dynamic> toJson() => _$HabitStreakModelToJson(this);
}

@JsonSerializable()
class DailyHabitModel {
  @JsonKey(name: 'habit_id')
  final int habitId;
  final String name;
  final String description;
  final String icon;
  final bool completed;

  const DailyHabitModel({
    required this.habitId,
    required this.name,
    this.description = '',
    this.icon = 'check_circle',
    this.completed = false,
  });

  factory DailyHabitModel.fromJson(Map<String, dynamic> json) =>
      _$DailyHabitModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyHabitModelToJson(this);
}
