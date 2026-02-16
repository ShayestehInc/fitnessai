/// Data model for an achievement with earned status.
class AchievementModel {
  final int id;
  final String name;
  final String description;
  final String iconName;
  final String criteriaType;
  final int criteriaValue;
  final bool earned;
  final DateTime? earnedAt;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.criteriaType,
    required this.criteriaValue,
    required this.earned,
    this.earnedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      criteriaType: json['criteria_type'] as String,
      criteriaValue: json['criteria_value'] as int,
      earned: json['earned'] as bool? ?? false,
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'] as String)
          : null,
    );
  }
}

/// Data model for a newly earned achievement (returned in API responses).
class NewAchievementModel {
  final int id;
  final String name;
  final String description;
  final String iconName;
  final DateTime earnedAt;

  const NewAchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.earnedAt,
  });

  factory NewAchievementModel.fromJson(Map<String, dynamic> json) {
    return NewAchievementModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}
