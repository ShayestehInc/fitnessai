import 'package:json_annotation/json_annotation.dart';

part 'progression_models.g.dart';

@JsonSerializable()
class ProgressionSuggestionModel {
  final int id;
  final int program;
  final int exercise;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'suggestion_data')
  final Map<String, dynamic> suggestionData;
  final String status;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const ProgressionSuggestionModel({
    required this.id,
    required this.program,
    required this.exercise,
    required this.exerciseName,
    required this.suggestionData,
    this.status = 'pending',
    this.createdAt,
  });

  double get currentWeight =>
      (suggestionData['current_weight'] as num?)?.toDouble() ?? 0;

  double get suggestedWeight =>
      (suggestionData['suggested_weight'] as num?)?.toDouble() ?? 0;

  int get currentReps =>
      (suggestionData['current_reps'] as num?)?.toInt() ?? 0;

  int get suggestedReps =>
      (suggestionData['suggested_reps'] as num?)?.toInt() ?? 0;

  String get rationale =>
      suggestionData['rationale'] as String? ?? '';

  String get unit =>
      suggestionData['unit'] as String? ?? 'lbs';

  String get suggestionType =>
      suggestionData['type'] as String? ?? 'weight';

  factory ProgressionSuggestionModel.fromJson(Map<String, dynamic> json) =>
      _$ProgressionSuggestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressionSuggestionModelToJson(this);
}

@JsonSerializable()
class DeloadRecommendationModel {
  @JsonKey(name: 'needs_deload')
  final bool needsDeload;
  final double confidence;
  final String rationale;
  @JsonKey(name: 'suggested_intensity_modifier')
  final double suggestedIntensityModifier;
  @JsonKey(name: 'suggested_volume_modifier')
  final double suggestedVolumeModifier;
  @JsonKey(name: 'weekly_volume_trend')
  final List<double> weeklyVolumeTrend;
  @JsonKey(name: 'fatigue_signals')
  final List<String> fatigueSignals;

  const DeloadRecommendationModel({
    this.needsDeload = false,
    this.confidence = 0,
    this.rationale = '',
    this.suggestedIntensityModifier = 1.0,
    this.suggestedVolumeModifier = 1.0,
    this.weeklyVolumeTrend = const [],
    this.fatigueSignals = const [],
  });

  factory DeloadRecommendationModel.fromJson(Map<String, dynamic> json) =>
      _$DeloadRecommendationModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeloadRecommendationModelToJson(this);
}
