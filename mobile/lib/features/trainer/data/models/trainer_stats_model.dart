import 'package:freezed_annotation/freezed_annotation.dart';

part 'trainer_stats_model.freezed.dart';
part 'trainer_stats_model.g.dart';

@freezed
class TrainerStatsModel with _$TrainerStatsModel {
  const factory TrainerStatsModel({
    @JsonKey(name: 'total_trainees') @Default(0) int totalTrainees,
    @JsonKey(name: 'active_trainees') @Default(0) int activeTrainees,
    @JsonKey(name: 'trainees_logged_today') @Default(0) int traineesLoggedToday,
    @JsonKey(name: 'trainees_on_track') @Default(0) int traineesOnTrack,
    @JsonKey(name: 'avg_adherence_rate') @Default(0.0) double avgAdherenceRate,
    @JsonKey(name: 'subscription_tier') @Default('NONE') String subscriptionTier,
    @JsonKey(name: 'max_trainees') @Default(0) int maxTrainees,
    @JsonKey(name: 'trainees_pending_onboarding') @Default(0) int traineesPendingOnboarding,
  }) = _TrainerStatsModel;

  factory TrainerStatsModel.fromJson(Map<String, dynamic> json) =>
      _$TrainerStatsModelFromJson(json);
}

@freezed
class TrainerDashboardModel with _$TrainerDashboardModel {
  const factory TrainerDashboardModel({
    @JsonKey(name: 'recent_trainees') @Default([]) List<dynamic> recentTrainees,
    @JsonKey(name: 'inactive_trainees') @Default([]) List<dynamic> inactiveTrainees,
    required String today,
  }) = _TrainerDashboardModel;

  factory TrainerDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$TrainerDashboardModelFromJson(json);
}
