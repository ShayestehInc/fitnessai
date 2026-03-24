import 'package:json_annotation/json_annotation.dart';

part 'triage_models.g.dart';

/// Result of starting a pain triage flow.
@JsonSerializable()
class TriageStartResult {
  @JsonKey(name: 'triage_response_id')
  final String triageResponseId;
  @JsonKey(name: 'pain_event_id')
  final String painEventId;
  @JsonKey(name: 'round_1_answers')
  final Map<String, dynamic> round1Answers;

  const TriageStartResult({
    required this.triageResponseId,
    required this.painEventId,
    this.round1Answers = const {},
  });

  factory TriageStartResult.fromJson(Map<String, dynamic> json) =>
      _$TriageStartResultFromJson(json);

  Map<String, dynamic> toJson() => _$TriageStartResultToJson(this);
}

/// A single remedy suggestion in the ladder.
@JsonSerializable()
class RemedySuggestion {
  final int order;
  @JsonKey(name: 'intervention_type')
  final String interventionType;
  final String description;
  final bool applicable;
  final Map<String, dynamic> details;

  const RemedySuggestion({
    required this.order,
    required this.interventionType,
    required this.description,
    this.applicable = true,
    this.details = const {},
  });

  factory RemedySuggestion.fromJson(Map<String, dynamic> json) =>
      _$RemedySuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$RemedySuggestionToJson(this);

  String get interventionLabel {
    switch (interventionType) {
      case 'cue_change':
        return 'Change Movement Cue';
      case 'tempo_pause':
        return 'Adjust Tempo / Add Pause';
      case 'load_reduction':
        return 'Reduce Load';
      case 'rom_reduction':
        return 'Shorten Range of Motion';
      case 'add_support':
        return 'Add Support / Change Stance';
      case 'regression':
        return 'Regress to Simpler Variation';
      case 'swap':
        return 'Swap Exercise';
      case 'stop':
        return 'Skip This Exercise';
      default:
        return interventionType;
    }
  }
}

/// Result of the round-2 submission (the remedy ladder).
@JsonSerializable()
class RemedyLadderResult {
  @JsonKey(name: 'triage_response_id')
  final String triageResponseId;
  final List<RemedySuggestion> suggestions;

  const RemedyLadderResult({
    required this.triageResponseId,
    this.suggestions = const [],
  });

  factory RemedyLadderResult.fromJson(Map<String, dynamic> json) =>
      _$RemedyLadderResultFromJson(json);

  Map<String, dynamic> toJson() => _$RemedyLadderResultToJson(this);
}

/// Result of finalizing a triage.
@JsonSerializable()
class TriageFinalizeResult {
  @JsonKey(name: 'triage_response_id')
  final String triageResponseId;
  @JsonKey(name: 'proceed_decision')
  final String proceedDecision;
  @JsonKey(name: 'trainer_notified')
  final bool trainerNotified;
  @JsonKey(name: 'decision_log_id')
  final String decisionLogId;

  const TriageFinalizeResult({
    required this.triageResponseId,
    required this.proceedDecision,
    this.trainerNotified = false,
    required this.decisionLogId,
  });

  factory TriageFinalizeResult.fromJson(Map<String, dynamic> json) =>
      _$TriageFinalizeResultFromJson(json);

  Map<String, dynamic> toJson() => _$TriageFinalizeResultToJson(this);

  String get proceedDecisionLabel {
    switch (proceedDecision) {
      case 'continue_as_planned':
        return 'Continue As Planned';
      case 'continue_with_adjustment':
        return 'Continue With Adjustment';
      case 'swap_exercise':
        return 'Swap Exercise';
      case 'skip_slot':
        return 'Skip This Exercise';
      case 'stop_session':
        return 'End Session';
      case 'seek_clinical_review':
        return 'Seek Clinical Review';
      default:
        return proceedDecision;
    }
  }
}
