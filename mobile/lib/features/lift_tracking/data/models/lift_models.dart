import 'package:freezed_annotation/freezed_annotation.dart';

part 'lift_models.freezed.dart';
part 'lift_models.g.dart';

@freezed
class E1rmHistoryEntry with _$E1rmHistoryEntry {
  const factory E1rmHistoryEntry({
    required String date,
    required double value,
  }) = _E1rmHistoryEntry;

  factory E1rmHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$E1rmHistoryEntryFromJson(json);
}

@freezed
class TopExerciseModel with _$TopExerciseModel {
  const factory TopExerciseModel({
    @JsonKey(name: 'exercise_id') required int exerciseId,
    @JsonKey(name: 'exercise_name') required String exerciseName,
    required double workload,
  }) = _TopExerciseModel;

  factory TopExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$TopExerciseModelFromJson(json);
}

@freezed
class DailyBreakdownModel with _$DailyBreakdownModel {
  const factory DailyBreakdownModel({
    required String date,
    required double workload,
    @JsonKey(name: 'session_label') String? sessionLabel,
  }) = _DailyBreakdownModel;

  factory DailyBreakdownModel.fromJson(Map<String, dynamic> json) =>
      _$DailyBreakdownModelFromJson(json);
}

@freezed
class LiftSetLogModel with _$LiftSetLogModel {
  const LiftSetLogModel._();

  const factory LiftSetLogModel({
    required int id,
    required int trainee,
    required int exercise,
    @JsonKey(name: 'session_date') required String sessionDate,
    @JsonKey(name: 'set_number') required int setNumber,
    @JsonKey(name: 'entered_load_value') required double enteredLoadValue,
    @JsonKey(name: 'entered_load_unit') required String enteredLoadUnit,
    @JsonKey(name: 'canonical_external_load_value')
    double? canonicalExternalLoadValue,
    @JsonKey(name: 'completed_reps') required int completedReps,
    double? rpe,
    @JsonKey(name: 'set_workload_value') double? setWorkloadValue,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _LiftSetLogModel;

  factory LiftSetLogModel.fromJson(Map<String, dynamic> json) =>
      _$LiftSetLogModelFromJson(json);

  String get loadDisplay =>
      '${enteredLoadValue.toStringAsFixed(enteredLoadValue.truncateToDouble() == enteredLoadValue ? 0 : 1)} $enteredLoadUnit';
}

@freezed
class LiftMaxModel with _$LiftMaxModel {
  const LiftMaxModel._();

  const factory LiftMaxModel({
    required int id,
    required int trainee,
    required int exercise,
    @JsonKey(name: 'exercise_name') required String exerciseName,
    @JsonKey(name: 'e1rm_current') double? e1rmCurrent,
    @JsonKey(name: 'e1rm_history')
    @Default([])
    List<E1rmHistoryEntry> e1rmHistory,
    @JsonKey(name: 'tm_current') double? tmCurrent,
    @JsonKey(name: 'tm_percentage') double? tmPercentage,
    @JsonKey(name: 'tm_history')
    @Default([])
    List<E1rmHistoryEntry> tmHistory,
  }) = _LiftMaxModel;

  factory LiftMaxModel.fromJson(Map<String, dynamic> json) =>
      _$LiftMaxModelFromJson(json);

  bool get hasE1rmData => e1rmCurrent != null && e1rmCurrent! > 0;
  bool get hasTmData => tmCurrent != null && tmCurrent! > 0;
}

@freezed
class WorkloadSessionModel with _$WorkloadSessionModel {
  const factory WorkloadSessionModel({
    @JsonKey(name: 'trainee_id') required int traineeId,
    @JsonKey(name: 'session_date') required String sessionDate,
    @JsonKey(name: 'total_workload') required double totalWorkload,
    @JsonKey(name: 'exercise_count') required int exerciseCount,
    @JsonKey(name: 'total_sets') required int totalSets,
    @JsonKey(name: 'total_reps') required int totalReps,
    @JsonKey(name: 'top_exercises')
    @Default([])
    List<TopExerciseModel> topExercises,
  }) = _WorkloadSessionModel;

  factory WorkloadSessionModel.fromJson(Map<String, dynamic> json) =>
      _$WorkloadSessionModelFromJson(json);
}

@freezed
class WorkloadWeeklyModel with _$WorkloadWeeklyModel {
  const WorkloadWeeklyModel._();

  const factory WorkloadWeeklyModel({
    @JsonKey(name: 'week_start') required String weekStart,
    @JsonKey(name: 'week_end') required String weekEnd,
    @JsonKey(name: 'total_workload') required double totalWorkload,
    @JsonKey(name: 'session_count') required int sessionCount,
    @JsonKey(name: 'by_muscle_group')
    @Default({})
    Map<String, double> byMuscleGroup,
    @JsonKey(name: 'by_pattern') @Default({}) Map<String, double> byPattern,
    @JsonKey(name: 'daily_breakdown')
    @Default([])
    List<DailyBreakdownModel> dailyBreakdown,
  }) = _WorkloadWeeklyModel;

  factory WorkloadWeeklyModel.fromJson(Map<String, dynamic> json) =>
      _$WorkloadWeeklyModelFromJson(json);

  double get averageWorkloadPerSession =>
      sessionCount > 0 ? totalWorkload / sessionCount : 0;
}

@freezed
class WeeklyDeltaModel with _$WeeklyDeltaModel {
  const factory WeeklyDeltaModel({
    required String week,
    required double workload,
    @JsonKey(name: 'delta_from_prior') double? deltaFromPrior,
  }) = _WeeklyDeltaModel;

  factory WeeklyDeltaModel.fromJson(Map<String, dynamic> json) =>
      _$WeeklyDeltaModelFromJson(json);
}

@freezed
class WorkloadTrendsModel with _$WorkloadTrendsModel {
  const WorkloadTrendsModel._();

  const factory WorkloadTrendsModel({
    @JsonKey(name: 'rolling_7_day') required double rolling7Day,
    @JsonKey(name: 'rolling_28_day') required double rolling28Day,
    @JsonKey(name: 'acute_chronic_ratio') required double acuteChronicRatio,
    @JsonKey(name: 'trend_direction') required String trendDirection,
    @JsonKey(name: 'spike_flag') @Default(false) bool spikeFlag,
    @JsonKey(name: 'dip_flag') @Default(false) bool dipFlag,
    @JsonKey(name: 'weekly_deltas')
    @Default([])
    List<WeeklyDeltaModel> weeklyDeltas,
  }) = _WorkloadTrendsModel;

  factory WorkloadTrendsModel.fromJson(Map<String, dynamic> json) =>
      _$WorkloadTrendsModelFromJson(json);

  bool get isInOptimalZone =>
      acuteChronicRatio >= 0.8 && acuteChronicRatio <= 1.3;

  String get acwrLabel {
    if (acuteChronicRatio < 0.8) return 'Undertraining';
    if (acuteChronicRatio <= 1.3) return 'Optimal';
    if (acuteChronicRatio <= 1.5) return 'Caution';
    return 'Danger';
  }
}
