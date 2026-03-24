import 'package:json_annotation/json_annotation.dart';

part 'video_message_model.g.dart';

@JsonSerializable()
class VideoMessageModel {
  @JsonKey(name: 'id')
  final String id;
  @JsonKey(name: 'capture_mode')
  final String captureMode;
  @JsonKey(name: 'duration_seconds')
  final double? durationSeconds;
  @JsonKey(name: 'upload_status')
  final String uploadStatus;
  @JsonKey(name: 'processing_status')
  final String processingStatus;
  @JsonKey(name: 'raw_upload_uri')
  final String rawUploadUri;
  @JsonKey(name: 'processed_stream_uri')
  final String processedStreamUri;
  @JsonKey(name: 'thumbnail_uri')
  final String thumbnailUri;
  @JsonKey(name: 'transcript_text')
  final String transcriptText;
  @JsonKey(name: 'transcript_confidence')
  final double? transcriptConfidence;
  @JsonKey(name: 'visibility_scope')
  final String visibilityScope;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const VideoMessageModel({
    required this.id,
    required this.captureMode,
    this.durationSeconds,
    this.uploadStatus = 'pending',
    this.processingStatus = 'pending',
    this.rawUploadUri = '',
    this.processedStreamUri = '',
    this.thumbnailUri = '',
    this.transcriptText = '',
    this.transcriptConfidence,
    this.visibilityScope = 'trainer_only',
    required this.createdAt,
  });

  factory VideoMessageModel.fromJson(Map<String, dynamic> json) =>
      _$VideoMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoMessageModelToJson(this);

  bool get isComplete => uploadStatus == 'complete';
  bool get isFailed => uploadStatus == 'failed';
  bool get hasTranscript => transcriptText.isNotEmpty;

  String get captureModeLabel {
    switch (captureMode) {
      case 'screen_only':
        return 'Screen Only';
      case 'front_only':
        return 'Front Camera';
      case 'rear_only':
        return 'Rear Camera';
      case 'screen_plus_front':
        return 'Screen + Front';
      case 'screen_plus_rear':
        return 'Screen + Rear';
      default:
        return captureMode;
    }
  }
}

@JsonSerializable()
class VideoMessageStartResult {
  @JsonKey(name: 'asset_id')
  final String assetId;
  @JsonKey(name: 'upload_status')
  final String uploadStatus;
  @JsonKey(name: 'capture_mode')
  final String captureMode;

  const VideoMessageStartResult({
    required this.assetId,
    required this.uploadStatus,
    required this.captureMode,
  });

  factory VideoMessageStartResult.fromJson(Map<String, dynamic> json) =>
      _$VideoMessageStartResultFromJson(json);

  Map<String, dynamic> toJson() => _$VideoMessageStartResultToJson(this);
}
