import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_request_model.freezed.dart';
part 'feature_request_model.g.dart';

@freezed
class FeatureRequestModel with _$FeatureRequestModel {
  const FeatureRequestModel._();

  const factory FeatureRequestModel({
    required int id,
    required String title,
    required String description,
    @Default('other') String category,
    @Default('submitted') String status,
    @JsonKey(name: 'submitted_by') int? submittedBy,
    @JsonKey(name: 'submitted_by_email') String? submittedByEmail,
    @JsonKey(name: 'submitted_by_name') String? submittedByName,
    @JsonKey(name: 'public_response') @Default('') String publicResponse,
    @JsonKey(name: 'target_release') @Default('') String targetRelease,
    @Default(0) int upvotes,
    @Default(0) int downvotes,
    @JsonKey(name: 'vote_score') @Default(0) int voteScore,
    @JsonKey(name: 'user_vote') String? userVote,
    @JsonKey(name: 'comment_count') @Default(0) int commentCount,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @Default([]) List<FeatureCommentModel> comments,
  }) = _FeatureRequestModel;

  factory FeatureRequestModel.fromJson(Map<String, dynamic> json) =>
      _$FeatureRequestModelFromJson(json);

  String get categoryDisplay {
    switch (category) {
      case 'trainer_tools':
        return 'Trainer Tools';
      case 'trainee_app':
        return 'Trainee App';
      case 'nutrition':
        return 'Nutrition';
      case 'workouts':
        return 'Workouts';
      case 'analytics':
        return 'Analytics';
      case 'integrations':
        return 'Integrations';
      default:
        return 'Other';
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'planned':
        return 'Planned';
      case 'in_development':
        return 'In Development';
      case 'released':
        return 'Released';
      case 'declined':
        return 'Declined';
      default:
        return status;
    }
  }

  bool get hasUserUpvoted => userVote == 'up';
  bool get hasUserDownvoted => userVote == 'down';
}

@freezed
class FeatureCommentModel with _$FeatureCommentModel {
  const factory FeatureCommentModel({
    required int id,
    required int feature,
    int? user,
    @JsonKey(name: 'user_email') String? userEmail,
    @JsonKey(name: 'user_name') String? userName,
    required String content,
    @JsonKey(name: 'is_admin_response') @Default(false) bool isAdminResponse,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _FeatureCommentModel;

  factory FeatureCommentModel.fromJson(Map<String, dynamic> json) =>
      _$FeatureCommentModelFromJson(json);
}

enum FeatureCategory {
  trainerTools('trainer_tools', 'Trainer Tools'),
  traineeApp('trainee_app', 'Trainee App'),
  nutrition('nutrition', 'Nutrition'),
  workouts('workouts', 'Workouts'),
  analytics('analytics', 'Analytics'),
  integrations('integrations', 'Integrations'),
  other('other', 'Other');

  final String value;
  final String display;

  const FeatureCategory(this.value, this.display);
}

enum FeatureStatus {
  submitted('submitted', 'Submitted'),
  underReview('under_review', 'Under Review'),
  planned('planned', 'Planned'),
  inDevelopment('in_development', 'In Development'),
  released('released', 'Released'),
  declined('declined', 'Declined');

  final String value;
  final String display;

  const FeatureStatus(this.value, this.display);
}
