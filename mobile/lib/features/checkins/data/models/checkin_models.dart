import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkin_models.freezed.dart';
part 'checkin_models.g.dart';

/// A check-in form template created by a trainer.
@freezed
class CheckInTemplateModel with _$CheckInTemplateModel {
  const CheckInTemplateModel._();

  const factory CheckInTemplateModel({
    required int id,
    int? trainer,
    @JsonKey(name: 'trainer_email') String? trainerEmail,
    required String name,
    @Default('weekly') String frequency,
    required List<CheckInFieldDefinition> fields,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _CheckInTemplateModel;

  factory CheckInTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$CheckInTemplateModelFromJson(json);

  String get frequencyDisplay {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Biweekly';
      case 'monthly':
        return 'Monthly';
      default:
        return frequency;
    }
  }
}

/// Definition of a single field within a check-in template.
@freezed
class CheckInFieldDefinition with _$CheckInFieldDefinition {
  const factory CheckInFieldDefinition({
    required String id,
    required String type,
    required String label,
    @Default(false) bool required,
    @Default([]) List<String> options,
  }) = _CheckInFieldDefinition;

  factory CheckInFieldDefinition.fromJson(Map<String, dynamic> json) =>
      _$CheckInFieldDefinitionFromJson(json);
}

/// An assignment of a check-in template to a trainee.
@freezed
class CheckInAssignmentModel with _$CheckInAssignmentModel {
  const factory CheckInAssignmentModel({
    required int id,
    required int template,
    @JsonKey(name: 'template_name') String? templateName,
    @JsonKey(name: 'template_fields') List<CheckInFieldDefinition>? templateFields,
    @JsonKey(name: 'template_frequency') String? templateFrequency,
    int? trainee,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    @JsonKey(name: 'next_due_date') required String nextDueDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _CheckInAssignmentModel;

  factory CheckInAssignmentModel.fromJson(Map<String, dynamic> json) =>
      _$CheckInAssignmentModelFromJson(json);
}

/// A completed check-in response submitted by a trainee.
@freezed
class CheckInResponseModel with _$CheckInResponseModel {
  const factory CheckInResponseModel({
    required int id,
    required int assignment,
    int? trainee,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    @JsonKey(name: 'template_name') String? templateName,
    required List<CheckInFieldResponse> responses,
    @JsonKey(name: 'trainer_notes') @Default('') String trainerNotes,
    @JsonKey(name: 'submitted_at') String? submittedAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _CheckInResponseModel;

  factory CheckInResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CheckInResponseModelFromJson(json);
}

/// A single field response within a check-in submission.
@freezed
class CheckInFieldResponse with _$CheckInFieldResponse {
  const factory CheckInFieldResponse({
    @JsonKey(name: 'field_id') required String fieldId,
    required dynamic value,
  }) = _CheckInFieldResponse;

  factory CheckInFieldResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckInFieldResponseFromJson(json);
}
