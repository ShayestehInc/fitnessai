import 'package:freezed_annotation/freezed_annotation.dart';

part 'impersonation_session_model.freezed.dart';
part 'impersonation_session_model.g.dart';

@freezed
class ImpersonationSessionModel with _$ImpersonationSessionModel {
  const ImpersonationSessionModel._();

  const factory ImpersonationSessionModel({
    required int id,
    required int trainee,
    @JsonKey(name: 'trainee_email') required String traineeEmail,
    @JsonKey(name: 'trainee_name') String? traineeName,
    @JsonKey(name: 'started_at') required String startedAt,
    @JsonKey(name: 'ended_at') String? endedAt,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'is_read_only') @Default(true) bool isReadOnly,
    @JsonKey(name: 'duration_minutes') @Default(0) int durationMinutes,
  }) = _ImpersonationSessionModel;

  factory ImpersonationSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ImpersonationSessionModelFromJson(json);
}

@freezed
class ImpersonationResponse with _$ImpersonationResponse {
  const factory ImpersonationResponse({
    required String access,
    required String refresh,
    required ImpersonationSessionModel session,
    required ImpersonatedTrainee trainee,
  }) = _ImpersonationResponse;

  factory ImpersonationResponse.fromJson(Map<String, dynamic> json) =>
      _$ImpersonationResponseFromJson(json);
}

@freezed
class ImpersonatedTrainee with _$ImpersonatedTrainee {
  const factory ImpersonatedTrainee({
    required int id,
    required String email,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
  }) = _ImpersonatedTrainee;

  factory ImpersonatedTrainee.fromJson(Map<String, dynamic> json) =>
      _$ImpersonatedTraineeFromJson(json);
}
