import 'package:freezed_annotation/freezed_annotation.dart';

part 'invitation_model.freezed.dart';
part 'invitation_model.g.dart';

@freezed
class InvitationModel with _$InvitationModel {
  const InvitationModel._();

  const factory InvitationModel({
    required int id,
    required String email,
    @JsonKey(name: 'invitation_code') required String invitationCode,
    required String status,
    @JsonKey(name: 'trainer_email') String? trainerEmail,
    @JsonKey(name: 'program_template') int? programTemplate,
    @JsonKey(name: 'program_template_name') String? programTemplateName,
    @Default('') String message,
    @JsonKey(name: 'expires_at') String? expiresAt,
    @JsonKey(name: 'accepted_at') String? acceptedAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'is_expired') @Default(false) bool isExpired,
  }) = _InvitationModel;

  factory InvitationModel.fromJson(Map<String, dynamic> json) =>
      _$InvitationModelFromJson(json);

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCancelled => status == 'cancelled';
}

@freezed
class CreateInvitationRequest with _$CreateInvitationRequest {
  const factory CreateInvitationRequest({
    required String email,
    @JsonKey(name: 'program_template_id') int? programTemplateId,
    @Default('') String message,
    @JsonKey(name: 'expires_days') @Default(7) int expiresDays,
  }) = _CreateInvitationRequest;

  factory CreateInvitationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateInvitationRequestFromJson(json);
}
