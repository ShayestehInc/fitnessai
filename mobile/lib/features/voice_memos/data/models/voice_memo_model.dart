import 'package:json_annotation/json_annotation.dart';

part 'voice_memo_model.g.dart';

@JsonSerializable()
class VoiceMemoModel {
  final int id;
  final String status;
  @JsonKey(name: 'audio_file')
  final String? audioFile;
  final String? transcript;
  @JsonKey(name: 'transcription_confidence')
  final double? transcriptionConfidence;
  @JsonKey(name: 'parsed_result')
  final Map<String, dynamic>? parsedResult;
  @JsonKey(name: 'daily_log')
  final int? dailyLog;
  @JsonKey(name: 'exercise_id')
  final int? exerciseId;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const VoiceMemoModel({
    required this.id,
    required this.status,
    this.audioFile,
    this.transcript,
    this.transcriptionConfidence,
    this.parsedResult,
    this.dailyLog,
    this.exerciseId,
    required this.createdAt,
  });

  factory VoiceMemoModel.fromJson(Map<String, dynamic> json) =>
      _$VoiceMemoModelFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceMemoModelToJson(this);

  /// Whether the memo is still being processed.
  bool get isProcessing =>
      status == 'uploaded' || status == 'transcribing';

  /// Whether the memo has completed processing successfully.
  bool get isComplete => status == 'transcribed' || status == 'parsed';

  /// Whether the memo failed processing.
  bool get isFailed => status == 'failed';

  /// Human-readable status label.
  String get statusLabel {
    switch (status) {
      case 'uploaded':
        return 'Uploaded';
      case 'transcribing':
        return 'Transcribing...';
      case 'transcribed':
        return 'Transcribed';
      case 'parsed':
        return 'Parsed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}
