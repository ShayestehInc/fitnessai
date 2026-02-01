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
    @JsonKey(name: 'image_url') String? imageUrl,
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

  /// Returns the program's image URL, or falls back to goal type image
  String get thumbnailUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    return ProgramGoals.imageUrl(goalType);
  }
}

@freezed
class TraineeProgramModel with _$TraineeProgramModel {
  const TraineeProgramModel._();

  const factory TraineeProgramModel({
    required int id,
    required String name,
    String? description,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'image_url') String? imageUrl,
    dynamic schedule,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'trainee') int? traineeId,
    @JsonKey(name: 'trainee_name') String? traineeName,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    @JsonKey(name: 'difficulty_level') String? difficultyLevel,
    @JsonKey(name: 'goal_type') String? goalType,
    @JsonKey(name: 'duration_weeks') int? durationWeeks,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _TraineeProgramModel;

  factory TraineeProgramModel.fromJson(Map<String, dynamic> json) =>
      _$TraineeProgramModelFromJson(json);

  /// Returns the program's image URL, or falls back to goal-based default
  String get thumbnailUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    return ProgramGoals.imageUrl(goalType ?? ProgramGoals.buildMuscle);
  }

  /// Get days per week from schedule if available
  int get daysPerWeek {
    if (schedule == null) return 0;
    try {
      List<dynamic>? weeksData;
      if (schedule is List && (schedule as List).isNotEmpty) {
        final firstWeek = (schedule as List).first;
        if (firstWeek is Map<String, dynamic>) {
          final days = firstWeek['days'] as List<dynamic>?;
          if (days != null) {
            return days.where((d) => d['is_rest_day'] != true).length;
          }
        }
      } else if (schedule is Map<String, dynamic>) {
        weeksData = schedule['weeks'] as List<dynamic>?;
        if (weeksData != null && weeksData.isNotEmpty) {
          final firstWeek = weeksData.first as Map<String, dynamic>;
          final days = firstWeek['days'] as List<dynamic>?;
          if (days != null) {
            return days.where((d) => d['is_rest_day'] != true).length;
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 0;
  }

  /// Get week schedule for preview (first week's day names)
  List<String> get weekSchedule {
    if (schedule == null) return [];
    try {
      List<dynamic>? weeksData;
      if (schedule is List && (schedule as List).isNotEmpty) {
        weeksData = schedule as List;
      } else if (schedule is Map<String, dynamic>) {
        weeksData = schedule['weeks'] as List<dynamic>?;
      }

      if (weeksData != null && weeksData.isNotEmpty) {
        final firstWeek = weeksData.first as Map<String, dynamic>;
        final days = firstWeek['days'] as List<dynamic>?;
        if (days != null) {
          return days.map((d) {
            if (d['is_rest_day'] == true) return 'Rest';
            return d['name']?.toString() ?? 'Workout';
          }).toList();
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return [];
  }
}

class ProgramGoals {
  static const String buildMuscle = 'build_muscle';
  static const String fatLoss = 'fat_loss';
  static const String strength = 'strength';
  static const String endurance = 'endurance';
  static const String recomp = 'recomp';
  static const String generalFitness = 'general_fitness';

  static const List<String> all = [buildMuscle, fatLoss, strength, endurance, recomp, generalFitness];

  static String displayName(String goal) {
    switch (goal) {
      case buildMuscle: return 'Build Muscle';
      case fatLoss: return 'Fat Loss';
      case strength: return 'Strength';
      case endurance: return 'Endurance';
      case recomp: return 'Body Recomp';
      case generalFitness: return 'General Fitness';
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
      case generalFitness: return '🎯';
      default: return '🎯';
    }
  }

  /// Returns a representative image URL for the goal type
  static String imageUrl(String goal) {
    switch (goal) {
      case buildMuscle:
        return 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&q=80';
      case fatLoss:
        return 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400&q=80';
      case strength:
        return 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400&q=80';
      case endurance:
        return 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=400&q=80';
      case recomp:
        return 'https://images.unsplash.com/photo-1581009146145-b5ef050c149a?w=400&q=80';
      case generalFitness:
      default:
        return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80';
    }
  }
}
