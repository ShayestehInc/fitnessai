import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_card_model.freezed.dart';
part 'share_card_model.g.dart';

@freezed
class ShareCardModel with _$ShareCardModel {
  const ShareCardModel._();

  const factory ShareCardModel({
    @JsonKey(name: 'workout_name') required String workoutName,
    required String date,
    @JsonKey(name: 'exercise_count') required int exerciseCount,
    @JsonKey(name: 'total_sets') required int totalSets,
    @JsonKey(name: 'total_volume') required double totalVolume,
    @JsonKey(name: 'volume_unit') required String volumeUnit,
    required String duration,
    required List<ShareCardExercise> exercises,
    @JsonKey(name: 'trainee_name') required String traineeName,
    @JsonKey(name: 'trainer_branding') required TrainerBranding trainerBranding,
  }) = _ShareCardModel;

  factory ShareCardModel.fromJson(Map<String, dynamic> json) =>
      _$ShareCardModelFromJson(json);

  String get volumeDisplay {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}k $volumeUnit';
    }
    return '${totalVolume.toStringAsFixed(0)} $volumeUnit';
  }
}

@freezed
class ShareCardExercise with _$ShareCardExercise {
  const factory ShareCardExercise({
    required String name,
    @Default(0) int sets,
    @Default(0) int reps,
    double? weight,
    @JsonKey(name: 'weight_unit') String? weightUnit,
  }) = _ShareCardExercise;

  factory ShareCardExercise.fromJson(Map<String, dynamic> json) =>
      _$ShareCardExerciseFromJson(json);
}

@freezed
class TrainerBranding with _$TrainerBranding {
  const factory TrainerBranding({
    @JsonKey(name: 'business_name') String? businessName,
    @JsonKey(name: 'primary_color') String? primaryColor,
    @JsonKey(name: 'secondary_color') String? secondaryColor,
    @JsonKey(name: 'logo_url') String? logoUrl,
  }) = _TrainerBranding;

  factory TrainerBranding.fromJson(Map<String, dynamic> json) =>
      _$TrainerBrandingFromJson(json);
}
