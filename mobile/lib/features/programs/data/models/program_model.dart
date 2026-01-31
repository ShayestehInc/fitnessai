import 'package:freezed_annotation/freezed_annotation.dart';

part 'program_model.freezed.dart';
part 'program_model.g.dart';

@freezed
class ProgramTemplateModel with _$ProgramTemplateModel {
  const ProgramTemplateModel._();

  const factory ProgramTemplateModel({
    required int id,
    required String name,
    String? description,
    @JsonKey(name: 'duration_weeks') required int durationWeeks,
    @JsonKey(name: 'difficulty_level') @Default('intermediate') String difficultyLevel,
    @JsonKey(name: 'goal_type') @Default('build_muscle') String goalType,
    @JsonKey(name: 'is_public') @Default(false) bool isPublic,
    @JsonKey(name: 'schedule_template') dynamic scheduleTemplate,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _ProgramTemplateModel;

  factory ProgramTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramTemplateModelFromJson(json);

  String get difficultyDisplay {
    switch (difficultyLevel) {
      case 'beginner': return 'Beginner';
      case 'intermediate': return 'Intermediate';
      case 'advanced': return 'Advanced';
      default: return difficultyLevel;
    }
  }

  String get goalTypeDisplay {
    switch (goalType) {
      case 'build_muscle': return 'Build Muscle';
      case 'fat_loss': return 'Fat Loss';
      case 'strength': return 'Strength';
      case 'endurance': return 'Endurance';
      case 'recomp': return 'Body Recomp';
      default: return goalType;
    }
  }
}

@freezed
class TraineeProgramModel with _$TraineeProgramModel {
  const factory TraineeProgramModel({
    required int id,
    required String name,
    String? description,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    dynamic schedule,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'trainee') int? traineeId,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _TraineeProgramModel;

  factory TraineeProgramModel.fromJson(Map<String, dynamic> json) =>
      _$TraineeProgramModelFromJson(json);
}

class ProgramGoals {
  static const String buildMuscle = 'build_muscle';
  static const String fatLoss = 'fat_loss';
  static const String strength = 'strength';
  static const String endurance = 'endurance';
  static const String recomp = 'recomp';

  static const List<String> all = [buildMuscle, fatLoss, strength, endurance, recomp];

  static String displayName(String goal) {
    switch (goal) {
      case buildMuscle: return 'Build Muscle';
      case fatLoss: return 'Fat Loss';
      case strength: return 'Strength';
      case endurance: return 'Endurance';
      case recomp: return 'Body Recomp';
      default: return goal;
    }
  }

  static String icon(String goal) {
    switch (goal) {
      case buildMuscle: return '💪';
      case fatLoss: return '🔥';
      case strength: return '🏋️';
      case endurance: return '🏃';
      case recomp: return '⚡';
      default: return '🎯';
    }
  }
}
