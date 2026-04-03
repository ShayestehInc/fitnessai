import 'package:freezed_annotation/freezed_annotation.dart';

part 'muscle_reference_model.freezed.dart';
part 'muscle_reference_model.g.dart';

@freezed
class MuscleReferenceModel with _$MuscleReferenceModel {
  const MuscleReferenceModel._();

  const factory MuscleReferenceModel({
    required String slug,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'latin_name') @Default('') String latinName,
    @JsonKey(name: 'body_region') required String bodyRegion,
    required String description,
    @Default('') String origin,
    @Default('') String insertion,
    @JsonKey(name: 'primary_movements') @Default([]) List<String> primaryMovements,
    @JsonKey(name: 'function_description') @Default('') String functionDescription,
    @JsonKey(name: 'training_tips') @Default('') String trainingTips,
    @JsonKey(name: 'common_exercises') @Default([]) List<String> commonExercises,
    @JsonKey(name: 'sub_muscles') @Default([]) List<SubMuscle> subMuscles,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _MuscleReferenceModel;

  factory MuscleReferenceModel.fromJson(Map<String, dynamic> json) =>
      _$MuscleReferenceModelFromJson(json);
}

@freezed
class SubMuscle with _$SubMuscle {
  const factory SubMuscle({
    required String name,
    @JsonKey(name: 'latin_name') @Default('') String latinName,
    @Default('') String description,
  }) = _SubMuscle;

  factory SubMuscle.fromJson(Map<String, dynamic> json) =>
      _$SubMuscleFromJson(json);
}

@freezed
class MuscleCoverageModel with _$MuscleCoverageModel {
  const factory MuscleCoverageModel({
    required String period,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    @JsonKey(name: 'muscle_intensities') @Default({}) Map<String, double> muscleIntensities,
    @JsonKey(name: 'muscle_workloads') @Default({}) Map<String, String> muscleWorkloads,
    @JsonKey(name: 'total_workload') @Default('0') String totalWorkload,
    @JsonKey(name: 'muscles_trained') @Default(0) int musclesTrained,
    @JsonKey(name: 'muscles_total') @Default(21) int musclesTotal,
  }) = _MuscleCoverageModel;

  factory MuscleCoverageModel.fromJson(Map<String, dynamic> json) =>
      _$MuscleCoverageModelFromJson(json);
}
