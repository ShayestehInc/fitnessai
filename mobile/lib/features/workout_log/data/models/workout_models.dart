import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_models.freezed.dart';
part 'workout_models.g.dart';

@freezed
class WorkoutSummary with _$WorkoutSummary {
  const factory WorkoutSummary({
    required String date,
    @Default([]) List<ExerciseEntry> exercises,
    @JsonKey(name: 'program_context') ProgramContext? programContext,
  }) = _WorkoutSummary;

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSummaryFromJson(json);
}

@freezed
class ExerciseEntry with _$ExerciseEntry {
  const factory ExerciseEntry({
    @JsonKey(name: 'exercise_id') int? exerciseId,
    @JsonKey(name: 'exercise_name') required String exerciseName,
    @Default([]) List<SetEntry> sets,
    String? timestamp,
  }) = _ExerciseEntry;

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) =>
      _$ExerciseEntryFromJson(json);
}

@freezed
class SetEntry with _$SetEntry {
  const factory SetEntry({
    @JsonKey(name: 'set_number') required int setNumber,
    required int reps,
    double? weight,
    @Default('lbs') String unit,
    @Default(true) bool completed,
  }) = _SetEntry;

  factory SetEntry.fromJson(Map<String, dynamic> json) =>
      _$SetEntryFromJson(json);
}

@freezed
class ProgramContext with _$ProgramContext {
  const factory ProgramContext({
    @JsonKey(name: 'program_id') required int programId,
    @JsonKey(name: 'program_name') required String programName,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
  }) = _ProgramContext;

  factory ProgramContext.fromJson(Map<String, dynamic> json) =>
      _$ProgramContextFromJson(json);
}

@freezed
class ProgramModel with _$ProgramModel {
  const ProgramModel._();

  const factory ProgramModel({
    required int id,
    int? trainee,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    required String name,
    @Default('') String description,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    // Schedule can be a List (from API) or Map (legacy format)
    dynamic schedule,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'difficulty_level') String? difficultyLevel,
    @JsonKey(name: 'goal_type') String? goalType,
    @JsonKey(name: 'duration_weeks') int? durationWeeks,
    @JsonKey(name: 'image_url') String? imageUrl,
  }) = _ProgramModel;

  /// Current week number based on start date (1-indexed).
  int get currentWeekNumber {
    try {
      final start = DateTime.parse(startDate);
      final now = DateTime.now();
      final diff = now.difference(start).inDays;
      return (diff ~/ 7) + 1;
    } catch (_) {
      return 1;
    }
  }

  /// Friendly display for difficulty.
  String get difficultyDisplay {
    final d = difficultyLevel;
    if (d == null || d.isEmpty) return 'Intermediate';
    return d[0].toUpperCase() + d.substring(1);
  }

  /// Friendly display for goal.
  String get goalDisplay {
    final g = goalType;
    if (g == null || g.isEmpty) return '';
    return g.replaceAll('_', ' ').split(' ').map(
      (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
    ).join(' ');
  }

  /// Weeks remaining from today.
  int get weeksRemaining {
    try {
      final end = DateTime.parse(endDate);
      final diff = end.difference(DateTime.now()).inDays;
      return (diff / 7).ceil().clamp(0, 999);
    } catch (_) {
      return 0;
    }
  }

  factory ProgramModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramModelFromJson(json);
}
