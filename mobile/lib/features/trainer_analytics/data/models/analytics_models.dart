import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_models.freezed.dart';
part 'analytics_models.g.dart';

@freezed
class CorrelationOverviewModel with _$CorrelationOverviewModel {
  const factory CorrelationOverviewModel({
    @JsonKey(name: 'period_days') required int periodDays,
    required List<CorrelationPointModel> correlations,
    required List<TraineeInsightModel> insights,
    @JsonKey(name: 'cohort_comparisons') required List<CohortComparisonModel> cohortComparisons,
  }) = _CorrelationOverviewModel;

  factory CorrelationOverviewModel.fromJson(Map<String, dynamic> json) =>
      _$CorrelationOverviewModelFromJson(json);
}

@freezed
class CorrelationPointModel with _$CorrelationPointModel {
  const CorrelationPointModel._();

  const factory CorrelationPointModel({
    @JsonKey(name: 'metric_a') required String metricA,
    @JsonKey(name: 'metric_b') required String metricB,
    required double correlation,
    @JsonKey(name: 'sample_size') required int sampleSize,
    required String interpretation,
  }) = _CorrelationPointModel;

  factory CorrelationPointModel.fromJson(Map<String, dynamic> json) =>
      _$CorrelationPointModelFromJson(json);

  String get strengthLabel {
    final abs = correlation.abs();
    if (abs >= 0.7) return 'Strong';
    if (abs >= 0.4) return 'Moderate';
    if (abs >= 0.2) return 'Weak';
    return 'Negligible';
  }

  bool get isPositive => correlation >= 0;
}

@freezed
class TraineeInsightModel with _$TraineeInsightModel {
  const TraineeInsightModel._();

  const factory TraineeInsightModel({
    @JsonKey(name: 'trainee_id') required int traineeId,
    @JsonKey(name: 'trainee_name') required String traineeName,
    @JsonKey(name: 'insight_type') required String insightType,
    required String severity,
    required String message,
    @Default({}) Map<String, dynamic> data,
  }) = _TraineeInsightModel;

  factory TraineeInsightModel.fromJson(Map<String, dynamic> json) =>
      _$TraineeInsightModelFromJson(json);

  bool get isWarning => severity == 'warning' || severity == 'high';
  bool get isInfo => severity == 'info' || severity == 'low';
  bool get isSuccess => severity == 'success' || severity == 'positive';
}

@freezed
class CohortComparisonModel with _$CohortComparisonModel {
  const factory CohortComparisonModel({
    required String metric,
    @JsonKey(name: 'high_adherence_avg') required double highAdherenceAvg,
    @JsonKey(name: 'low_adherence_avg') required double lowAdherenceAvg,
    @JsonKey(name: 'difference_pct') required double differencePct,
    @JsonKey(name: 'high_count') required int highCount,
    @JsonKey(name: 'low_count') required int lowCount,
  }) = _CohortComparisonModel;

  factory CohortComparisonModel.fromJson(Map<String, dynamic> json) =>
      _$CohortComparisonModelFromJson(json);
}

@freezed
class TraineePatternsModel with _$TraineePatternsModel {
  const factory TraineePatternsModel({
    @JsonKey(name: 'trainee_id') required int traineeId,
    @JsonKey(name: 'trainee_name') required String traineeName,
    @JsonKey(name: 'period_days') required int periodDays,
    required List<TraineeInsightModel> insights,
    @JsonKey(name: 'exercise_progressions') required List<ExerciseProgressionModel> exerciseProgressions,
    @JsonKey(name: 'adherence_stats') required AdherenceStatsModel adherenceStats,
  }) = _TraineePatternsModel;

  factory TraineePatternsModel.fromJson(Map<String, dynamic> json) =>
      _$TraineePatternsModelFromJson(json);
}

@freezed
class ExerciseProgressionModel with _$ExerciseProgressionModel {
  const ExerciseProgressionModel._();

  const factory ExerciseProgressionModel({
    @JsonKey(name: 'exercise_id') required int exerciseId,
    @JsonKey(name: 'exercise_name') required String exerciseName,
    @JsonKey(name: 'trainee_id') required int traineeId,
    @JsonKey(name: 'e1rm_start') required double e1rmStart,
    @JsonKey(name: 'e1rm_current') required double e1rmCurrent,
    @JsonKey(name: 'change_pct') required double changePct,
    @JsonKey(name: 'sessions_count') required int sessionsCount,
    required String trend,
  }) = _ExerciseProgressionModel;

  factory ExerciseProgressionModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseProgressionModelFromJson(json);

  bool get isProgressing => trend == 'up' || changePct > 0;
  bool get isRegressing => trend == 'down' || changePct < 0;
  bool get isFlat => trend == 'flat' || changePct == 0;
}

@freezed
class AdherenceStatsModel with _$AdherenceStatsModel {
  const factory AdherenceStatsModel({
    @JsonKey(name: 'food_logging_pct') @Default(0.0) double foodLoggingPct,
    @JsonKey(name: 'workout_logging_pct') @Default(0.0) double workoutLoggingPct,
    @JsonKey(name: 'protein_adherence_pct') @Default(0.0) double proteinAdherencePct,
    @JsonKey(name: 'calorie_adherence_pct') @Default(0.0) double calorieAdherencePct,
    @JsonKey(name: 'sleep_logging_pct') @Default(0.0) double sleepLoggingPct,
  }) = _AdherenceStatsModel;

  factory AdherenceStatsModel.fromJson(Map<String, dynamic> json) =>
      _$AdherenceStatsModelFromJson(json);
}

@freezed
class AuditSummaryModel with _$AuditSummaryModel {
  const factory AuditSummaryModel({
    @JsonKey(name: 'total_decisions') required int totalDecisions,
    @JsonKey(name: 'recent_decisions_7d') required int recentDecisions7d,
    @JsonKey(name: 'by_type') required List<AuditCountModel> byType,
    @JsonKey(name: 'by_actor') required List<AuditCountModel> byActor,
    @JsonKey(name: 'reverted_count') required int revertedCount,
    @JsonKey(name: 'period_days') required int periodDays,
  }) = _AuditSummaryModel;

  factory AuditSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$AuditSummaryModelFromJson(json);
}

@freezed
class AuditCountModel with _$AuditCountModel {
  const factory AuditCountModel({
    @JsonKey(name: 'decision_type') String? decisionType,
    @JsonKey(name: 'actor_type') String? actorType,
    required int count,
  }) = _AuditCountModel;

  factory AuditCountModel.fromJson(Map<String, dynamic> json) =>
      _$AuditCountModelFromJson(json);
}

@freezed
class AuditTimelineEntryModel with _$AuditTimelineEntryModel {
  const factory AuditTimelineEntryModel({
    @JsonKey(name: 'decision_id') required String decisionId,
    required String timestamp,
    @JsonKey(name: 'actor_type') required String actorType,
    @JsonKey(name: 'actor_email') String? actorEmail,
    @JsonKey(name: 'decision_type') required String decisionType,
    required String description,
    @JsonKey(name: 'is_reverted') @Default(false) bool isReverted,
    @Default('') String context,
  }) = _AuditTimelineEntryModel;

  factory AuditTimelineEntryModel.fromJson(Map<String, dynamic> json) =>
      _$AuditTimelineEntryModelFromJson(json);
}
