import 'package:json_annotation/json_annotation.dart';

part 'progress_photo_model.g.dart';

@JsonSerializable()
class ProgressPhotoModel {
  final int id;
  final String? trainee;
  @JsonKey(name: 'trainee_email')
  final String? traineeEmail;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  final String category;
  final String date;
  final Map<String, dynamic> measurements;
  final String notes;

  const ProgressPhotoModel({
    required this.id,
    this.trainee,
    this.traineeEmail,
    this.photoUrl,
    required this.category,
    required this.date,
    this.measurements = const {},
    this.notes = '',
  });

  factory ProgressPhotoModel.fromJson(Map<String, dynamic> json) =>
      _$ProgressPhotoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressPhotoModelToJson(this);

  /// Returns the measurement value for a given key, or null if not present.
  double? getMeasurement(String key) {
    final value = measurements[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Returns true if this photo has any body measurements recorded.
  bool get hasMeasurements => measurements.isNotEmpty;

  /// Human-readable category label.
  String get categoryLabel {
    switch (category) {
      case 'front':
        return 'Front';
      case 'side':
        return 'Side';
      case 'back':
        return 'Back';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }
}

@JsonSerializable()
class PhotoComparisonResult {
  @JsonKey(name: 'photo1')
  final ProgressPhotoModel photo1;
  @JsonKey(name: 'photo2')
  final ProgressPhotoModel photo2;
  @JsonKey(name: 'measurement_diff')
  final Map<String, dynamic> measurementDiff;

  const PhotoComparisonResult({
    required this.photo1,
    required this.photo2,
    this.measurementDiff = const {},
  });

  factory PhotoComparisonResult.fromJson(Map<String, dynamic> json) =>
      _$PhotoComparisonResultFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoComparisonResultToJson(this);
}
