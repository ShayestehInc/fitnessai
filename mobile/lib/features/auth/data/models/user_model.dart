import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class TrainerModel with _$TrainerModel {
  const factory TrainerModel({
    required int id,
    required String email,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'profile_image') String? profileImage,
  }) = _TrainerModel;

  factory TrainerModel.fromJson(Map<String, dynamic> json) =>
      _$TrainerModelFromJson(json);
}

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required int id,
    required String email,
    @JsonKey(name: 'role') required String role,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'onboarding_completed') @Default(false) bool onboardingCompleted,
    TrainerModel? trainer,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  bool get isTrainer => role == 'TRAINER';
  bool get isTrainee => role == 'TRAINEE';
  bool get isAdmin => role == 'ADMIN';
  bool get needsOnboarding => isTrainee && !onboardingCompleted;
  bool get hasTrainer => trainer != null;

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!;
    }
    return email.split('@').first;
  }
}
