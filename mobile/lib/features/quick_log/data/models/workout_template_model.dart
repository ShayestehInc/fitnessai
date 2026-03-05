import 'package:json_annotation/json_annotation.dart';

part 'workout_template_model.g.dart';

@JsonSerializable()
class WorkoutTemplateModel {
  final int id;
  final String name;
  final String category;
  final String description;
  @JsonKey(name: 'estimated_duration_minutes')
  final int estimatedDurationMinutes;
  @JsonKey(name: 'default_calories_per_minute')
  final double defaultCaloriesPerMinute;
  @JsonKey(name: 'is_public')
  final bool isPublic;

  const WorkoutTemplateModel({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    this.estimatedDurationMinutes = 30,
    this.defaultCaloriesPerMinute = 5.0,
    this.isPublic = true,
  });

  factory WorkoutTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTemplateModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutTemplateModelToJson(this);

  /// Returns the estimated calories for a given duration in minutes.
  double estimatedCalories(int durationMinutes) {
    return defaultCaloriesPerMinute * durationMinutes;
  }

  /// Human-readable category display name.
  String get categoryDisplay {
    switch (category.toLowerCase()) {
      case 'cardio':
        return 'Cardio';
      case 'sports':
        return 'Sports';
      case 'outdoor':
        return 'Outdoor';
      case 'flexibility':
        return 'Flexibility';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  /// Icon data key for the category (used by the UI layer to pick an icon).
  static String categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return 'cardio';
      case 'sports':
        return 'sports';
      case 'outdoor':
        return 'outdoor';
      case 'flexibility':
        return 'flexibility';
      case 'other':
      default:
        return 'other';
    }
  }
}

/// All supported quick-log categories.
class QuickLogCategories {
  static const String cardio = 'cardio';
  static const String sports = 'sports';
  static const String outdoor = 'outdoor';
  static const String flexibility = 'flexibility';
  static const String other = 'other';

  static const List<String> all = [
    cardio,
    sports,
    outdoor,
    flexibility,
    other,
  ];

  static String displayName(String category) {
    switch (category) {
      case cardio:
        return 'Cardio';
      case sports:
        return 'Sports';
      case outdoor:
        return 'Outdoor';
      case flexibility:
        return 'Flexibility';
      case other:
        return 'Other';
      default:
        return category;
    }
  }
}
