import 'package:json_annotation/json_annotation.dart';

part 'auto_tag_model.g.dart';

@JsonSerializable()
class AutoTagDraftModel {
  final int id;

  @JsonKey(name: 'exercise_id')
  final int exerciseId;

  final String status;

  @JsonKey(name: 'proposed_tags')
  final Map<String, dynamic>? proposedTags;

  @JsonKey(name: 'current_tags')
  final Map<String, dynamic>? currentTags;

  final double? confidence;

  @JsonKey(name: 'created_at')
  final String createdAt;

  const AutoTagDraftModel({
    required this.id,
    required this.exerciseId,
    required this.status,
    this.proposedTags,
    this.currentTags,
    this.confidence,
    required this.createdAt,
  });

  factory AutoTagDraftModel.fromJson(Map<String, dynamic> json) =>
      _$AutoTagDraftModelFromJson(json);

  Map<String, dynamic> toJson() => _$AutoTagDraftModelToJson(this);

  bool get isPending => status == 'pending';
  bool get isApplied => status == 'applied';
  bool get isRejected => status == 'rejected';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'applied':
        return 'Applied';
      case 'rejected':
        return 'Rejected';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  String get confidenceLabel {
    if (confidence == null) return 'Unknown';
    if (confidence! >= 0.9) return 'Very High';
    if (confidence! >= 0.7) return 'High';
    if (confidence! >= 0.5) return 'Medium';
    return 'Low';
  }
}

@JsonSerializable()
class TagHistoryEntryModel {
  final int id;

  final String action;

  final Map<String, dynamic> tags;

  @JsonKey(name: 'applied_by')
  final String? appliedBy;

  @JsonKey(name: 'applied_at')
  final String appliedAt;

  const TagHistoryEntryModel({
    required this.id,
    required this.action,
    required this.tags,
    this.appliedBy,
    required this.appliedAt,
  });

  factory TagHistoryEntryModel.fromJson(Map<String, dynamic> json) =>
      _$TagHistoryEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$TagHistoryEntryModelToJson(this);

  String get actionDisplay {
    switch (action) {
      case 'auto_tag':
        return 'Auto-Tagged';
      case 'manual':
        return 'Manual Edit';
      case 'applied':
        return 'Draft Applied';
      case 'rejected':
        return 'Draft Rejected';
      case 'reverted':
        return 'Reverted';
      default:
        return action.replaceAll('_', ' ');
    }
  }
}
