import 'package:freezed_annotation/freezed_annotation.dart';

part 'decision_log_model.freezed.dart';
part 'decision_log_model.g.dart';

@freezed
class DecisionLogModel with _$DecisionLogModel {
  const DecisionLogModel._();

  const factory DecisionLogModel({
    required String id,
    required String timestamp,
    @JsonKey(name: 'actor_type') required String actorType,
    int? actor,
    @JsonKey(name: 'decision_type') required String decisionType,
    @Default('') String context,
    @JsonKey(name: 'inputs_snapshot') @Default({}) Map<String, dynamic> inputsSnapshot,
    @JsonKey(name: 'constraints_applied') @Default([]) List<dynamic> constraintsApplied,
    @JsonKey(name: 'options_considered') @Default([]) List<dynamic> optionsConsidered,
    @JsonKey(name: 'final_choice') @Default({}) Map<String, dynamic> finalChoice,
    @JsonKey(name: 'reason_codes') @Default([]) List<String> reasonCodes,
    @JsonKey(name: 'override_info') Map<String, dynamic>? overrideInfo,
    @JsonKey(name: 'undo_snapshot') String? undoSnapshot,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _DecisionLogModel;

  factory DecisionLogModel.fromJson(Map<String, dynamic> json) =>
      _$DecisionLogModelFromJson(json);

  String get decisionTypeDisplay {
    switch (decisionType) {
      case 'exercise_swap':
        return 'Exercise Swap';
      case 'load_assignment':
        return 'Load Assignment';
      case 'deload_trigger':
        return 'Deload Trigger';
      case 'progression':
        return 'Progression';
      case 'plan_generation':
        return 'Plan Generation';
      case 'modality_selection':
        return 'Modality Selection';
      default:
        return decisionType.replaceAll('_', ' ').split(' ').map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        ).join(' ');
    }
  }

  String get actorTypeDisplay {
    switch (actorType) {
      case 'system':
        return 'System';
      case 'trainer':
        return 'Trainer';
      case 'trainee':
        return 'Trainee';
      case 'admin':
        return 'Admin';
      default:
        return actorType;
    }
  }

  bool get canUndo => undoSnapshot != null;

  String get finalChoiceSummary {
    if (finalChoice.containsKey('description')) {
      return finalChoice['description'].toString();
    }
    if (finalChoice.containsKey('name')) {
      return finalChoice['name'].toString();
    }
    if (finalChoice.containsKey('value')) {
      return finalChoice['value'].toString();
    }
    if (finalChoice.isEmpty) return 'No details';
    return finalChoice.entries
        .take(3)
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }
}

@freezed
class DecisionLogListResponse with _$DecisionLogListResponse {
  const factory DecisionLogListResponse({
    required int count,
    String? next,
    String? previous,
    required List<DecisionLogModel> results,
  }) = _DecisionLogListResponse;

  factory DecisionLogListResponse.fromJson(Map<String, dynamic> json) =>
      _$DecisionLogListResponseFromJson(json);
}
