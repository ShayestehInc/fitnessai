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
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'is_public') @Default(true) bool isPublic,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    // v6.5 fields
    @JsonKey(name: 'primary_muscle_group') String? primaryMuscleGroup,
    @JsonKey(name: 'secondary_muscle_groups') @Default([]) List<String> secondaryMuscleGroups,
    @JsonKey(name: 'muscle_contribution_map') @Default({}) Map<String, double> muscleContributionMap,
    @JsonKey(name: 'pattern_tags') @Default([]) List<String> patternTags,
    String? stance,
    String? plane,
    @JsonKey(name: 'rom_bias') String? romBias,
    @JsonKey(name: 'equipment_required') @Default([]) List<String> equipmentRequired,
    @JsonKey(name: 'equipment_optional') @Default([]) List<String> equipmentOptional,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);

  String get muscleGroupDisplay {
    return muscleGroup.replaceAll('_', ' ').split(' ').map((word) =>
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  /// Returns the exercise's image URL, or falls back to muscle group image
  String get thumbnailUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    return MuscleGroups.imageUrl(muscleGroup);
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

  /// Returns a local asset path for the muscle group fallback image
  static String assetPath(String muscleGroup) {
    final key = muscleGroup.toLowerCase();
    if (all.contains(key)) {
      return 'assets/muscle_groups/$key.jpg';
    }
    return 'assets/muscle_groups/other.jpg';
  }

  /// Returns a representative image URL for the muscle group (network fallback)
  static String imageUrl(String muscleGroup) {
    switch (muscleGroup) {
      case chest:
        return 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&q=80';
      case back:
        return 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=400&q=80';
      case shoulders:
        return 'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=400&q=80';
      case arms:
        return 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&q=80';
      case legs:
        return 'https://images.unsplash.com/photo-1434608519344-49d77a699e1d?w=400&q=80';
      case glutes:
        return 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&q=80';
      case core:
        return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80';
      case cardio:
        return 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400&q=80';
      case fullBody:
        return 'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=400&q=80';
      case other:
      default:
        return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80';
    }
  }
}
