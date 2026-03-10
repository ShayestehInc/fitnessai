import 'package:json_annotation/json_annotation.dart';

part 'program_import_model.g.dart';

@JsonSerializable()
class ProgramImportModel {
  final int id;
  final String status;
  @JsonKey(name: 'original_file')
  final String? originalFile;
  @JsonKey(name: 'file_name')
  final String? fileName;
  @JsonKey(name: 'parsed_program')
  final Map<String, dynamic>? parsedProgram;
  final List<String>? warnings;
  final List<String>? errors;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const ProgramImportModel({
    required this.id,
    required this.status,
    this.originalFile,
    this.fileName,
    this.parsedProgram,
    this.warnings,
    this.errors,
    required this.createdAt,
  });

  factory ProgramImportModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramImportModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramImportModelToJson(this);

  /// Whether the import is still being processed by the backend.
  bool get isProcessing => status == 'uploaded' || status == 'parsing';

  /// Whether the parsed program is ready for review and confirmation.
  bool get isReady => status == 'parsed';

  /// Whether the import has failed.
  bool get isFailed => status == 'failed';

  /// Whether the import has been confirmed and applied.
  bool get isConfirmed => status == 'confirmed';

  /// Whether this import has any warnings from parsing.
  bool get hasWarnings => warnings != null && warnings!.isNotEmpty;

  /// Whether this import has any errors from parsing.
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  /// Human-readable status label.
  String get statusLabel {
    switch (status) {
      case 'uploaded':
        return 'Uploaded';
      case 'parsing':
        return 'Parsing...';
      case 'parsed':
        return 'Ready for Review';
      case 'confirmed':
        return 'Confirmed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}
