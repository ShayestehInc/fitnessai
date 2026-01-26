import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_model.freezed.dart';
part 'exercise_model.g.dart';

@freezed
class ExerciseModel with _$ExerciseModel {
  const ExerciseModel._();

  const factory ExerciseModel({
    required int id,
    required String name,
    @JsonKey(name: 'muscle_group') required String muscleGroup,
    String? description,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'is_public') @Default(true) bool isPublic,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);

  String get muscleGroupDisplay {
    return muscleGroup.replaceAll('_', ' ').split(' ').map((word) =>
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }
}

// Muscle groups matching backend choices
class MuscleGroups {
  static const String chest = 'chest';
  static const String back = 'back';
  static const String shoulders = 'shoulders';
  static const String arms = 'arms';
  static const String legs = 'legs';
  static const String glutes = 'glutes';
  static const String core = 'core';
  static const String cardio = 'cardio';
  static const String fullBody = 'full_body';
  static const String other = 'other';

  static const List<String> all = [
    chest, back, shoulders, arms, legs, glutes, core, cardio, fullBody, other
  ];

  static String displayName(String muscleGroup) {
    switch (muscleGroup) {
      case chest: return 'Chest';
      case back: return 'Back';
      case shoulders: return 'Shoulders';
      case arms: return 'Arms';
      case legs: return 'Legs';
      case glutes: return 'Glutes';
      case core: return 'Core';
      case cardio: return 'Cardio';
      case fullBody: return 'Full Body';
      case other: return 'Other';
      default: return muscleGroup;
    }
  }
}
