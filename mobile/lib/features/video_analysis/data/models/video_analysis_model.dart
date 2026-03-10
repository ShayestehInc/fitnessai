import 'package:json_annotation/json_annotation.dart';

part 'video_analysis_model.g.dart';

@JsonSerializable()
class VideoAnalysisModel {
  final int id;
  final String status;
  @JsonKey(name: 'video_file')
  final String? videoFile;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'exercise_id')
  final int? exerciseId;
  @JsonKey(name: 'exercise_name')
  final String? exerciseName;
  final Map<String, dynamic>? analysis;
  final List<String>? suggestions;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const VideoAnalysisModel({
    required this.id,
    required this.status,
    this.videoFile,
    this.thumbnailUrl,
    this.exerciseId,
    this.exerciseName,
    this.analysis,
    this.suggestions,
    required this.createdAt,
  });

  factory VideoAnalysisModel.fromJson(Map<String, dynamic> json) =>
      _$VideoAnalysisModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoAnalysisModelToJson(this);

  /// Whether the analysis is still being processed.
  bool get isProcessing =>
      status == 'uploaded' || status == 'processing';

  /// Whether the analysis has completed successfully.
  bool get isComplete => status == 'completed';

  /// Whether the analysis failed processing.
  bool get isFailed => status == 'failed';

  /// Human-readable status label.
  String get statusLabel {
    switch (status) {
      case 'uploaded':
        return 'Uploaded';
      case 'processing':
        return 'Analyzing...';
      case 'completed':
        return 'Complete';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}
