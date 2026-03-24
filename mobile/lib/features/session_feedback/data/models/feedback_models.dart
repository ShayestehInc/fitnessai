import 'package:json_annotation/json_annotation.dart';

part 'feedback_models.g.dart';

@JsonSerializable()
class SessionFeedbackModel {
  final int id;
  @JsonKey(name: 'active_session_id')
  final int? activeSessionId;
  @JsonKey(name: 'completion_state')
  final String completionState;
  final Map<String, int> ratings;
  @JsonKey(name: 'friction_reasons')
  final List<String> frictionReasons;
  @JsonKey(name: 'recovery_concern')
  final bool recoveryConcern;
  @JsonKey(name: 'win_reasons')
  final List<String> winReasons;
  @JsonKey(name: 'session_volume_perception')
  final String sessionVolumePerception;
  @JsonKey(name: 'requested_action')
  final String requestedAction;
  final String notes;
  @JsonKey(name: 'pain_events')
  final List<PainEventModel> painEvents;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const SessionFeedbackModel({
    required this.id,
    this.activeSessionId,
    required this.completionState,
    this.ratings = const {},
    this.frictionReasons = const [],
    this.recoveryConcern = false,
    this.winReasons = const [],
    this.sessionVolumePerception = '',
    this.requestedAction = '',
    this.notes = '',
    this.painEvents = const [],
    required this.createdAt,
  });

  factory SessionFeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$SessionFeedbackModelFromJson(json);

  Map<String, dynamic> toJson() => _$SessionFeedbackModelToJson(this);

  /// Human-readable completion state label.
  String get completionStateLabel {
    switch (completionState) {
      case 'completed':
        return 'Completed';
      case 'partial':
        return 'Partial';
      case 'skipped':
        return 'Skipped';
      default:
        return completionState;
    }
  }
}

@JsonSerializable()
class PainEventModel {
  final int? id;
  @JsonKey(name: 'body_region')
  final String bodyRegion;
  @JsonKey(name: 'pain_score')
  final int painScore;
  final String? side;
  @JsonKey(name: 'sensation_type')
  final String? sensationType;
  @JsonKey(name: 'onset_phase')
  final String? onsetPhase;
  @JsonKey(name: 'warmup_effect')
  final String? warmupEffect;
  @JsonKey(name: 'exercise_id')
  final int? exerciseId;
  @JsonKey(name: 'active_session_id')
  final int? activeSessionId;
  final String notes;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const PainEventModel({
    this.id,
    required this.bodyRegion,
    required this.painScore,
    this.side,
    this.sensationType,
    this.onsetPhase,
    this.warmupEffect,
    this.exerciseId,
    this.activeSessionId,
    this.notes = '',
    this.createdAt,
  });

  factory PainEventModel.fromJson(Map<String, dynamic> json) =>
      _$PainEventModelFromJson(json);

  Map<String, dynamic> toJson() => _$PainEventModelToJson(this);

  /// Human-readable body region label.
  String get bodyRegionLabel {
    return bodyRegion
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  /// Pain severity label based on score.
  String get severityLabel {
    if (painScore <= 3) return 'Mild';
    if (painScore <= 6) return 'Moderate';
    return 'Severe';
  }
}

@JsonSerializable()
class FeedbackSubmitResult {
  @JsonKey(name: 'feedback_id')
  final int feedbackId;
  @JsonKey(name: 'active_session_id')
  final int? activeSessionId;
  @JsonKey(name: 'pain_events_created')
  final int painEventsCreated;
  @JsonKey(name: 'triggered_rules')
  final List<TriggeredRule> triggeredRules;

  const FeedbackSubmitResult({
    required this.feedbackId,
    this.activeSessionId,
    this.painEventsCreated = 0,
    this.triggeredRules = const [],
  });

  factory FeedbackSubmitResult.fromJson(Map<String, dynamic> json) =>
      _$FeedbackSubmitResultFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackSubmitResultToJson(this);
}

@JsonSerializable()
class TriggeredRule {
  @JsonKey(name: 'rule_id')
  final String ruleId;
  @JsonKey(name: 'rule_type')
  final String ruleType;
  final String reason;

  const TriggeredRule({
    required this.ruleId,
    required this.ruleType,
    required this.reason,
  });

  factory TriggeredRule.fromJson(Map<String, dynamic> json) =>
      _$TriggeredRuleFromJson(json);

  Map<String, dynamic> toJson() => _$TriggeredRuleToJson(this);
}
