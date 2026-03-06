/// Video attached to a community post.
class PostVideoModel {
  final int? id;
  final String url;
  final String? thumbnailUrl;
  final double? duration;
  final int? fileSize;
  final int sortOrder;

  const PostVideoModel({
    this.id,
    required this.url,
    this.thumbnailUrl,
    this.duration,
    this.fileSize,
    this.sortOrder = 0,
  });

  factory PostVideoModel.fromJson(Map<String, dynamic> json) {
    return PostVideoModel(
      id: json['id'] as int?,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      duration: (json['duration'] as num?)?.toDouble(),
      fileSize: json['file_size'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Format duration as M:SS (e.g., "1:05" or "0:32").
  String get formattedDuration {
    if (duration == null) return '';
    final totalSeconds = duration!.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
