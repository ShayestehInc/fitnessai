import 'package:json_annotation/json_annotation.dart';

part 'progression_profile_model.g.dart';

@JsonSerializable()
class ProgressionProfileModel {
  final int id;
  final int trainee;
  @JsonKey(name: 'training_plan')
  final int? trainingPlan;
  final String strategy;
  final ProgressionConfigModel config;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const ProgressionProfileModel({
    required this.id,
    required this.trainee,
    this.trainingPlan,
    required this.strategy,
    required this.config,
    required this.createdAt,
  });

  String get strategyDisplay {
    switch (strategy) {
      case 'staircase':
        return 'Staircase';
      case 'wave':
        return 'Wave';
      case 'deload':
        return 'Auto-Deload';
      default:
        return strategy;
    }
  }

  String get strategyDescription {
    switch (strategy) {
      case 'staircase':
        return 'Gradually increase load each session in a linear fashion.';
      case 'wave':
        return 'Cycle through light, medium, and heavy sessions.';
      case 'deload':
        return 'Automatically reduce load when fatigue signals are detected.';
      default:
        return '';
    }
  }

  factory ProgressionProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProgressionProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressionProfileModelToJson(this);
}

@JsonSerializable()
class ProgressionConfigModel {
  @JsonKey(name: 'step_size')
  final double stepSize;
  @JsonKey(name: 'deload_frequency')
  final int deloadFrequency;
  @JsonKey(name: 'wave_pattern')
  final List<String> wavePattern;

  const ProgressionConfigModel({
    this.stepSize = 2.5,
    this.deloadFrequency = 4,
    this.wavePattern = const ['light', 'medium', 'heavy'],
  });

  factory ProgressionConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ProgressionConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressionConfigModelToJson(this);
}

@JsonSerializable()
class ProgressionPlanSuggestionModel {
  final int id;
  final int trainee;
  @JsonKey(name: 'plan_slot')
  final int? planSlot;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'suggestion_type')
  final String suggestionType;
  @JsonKey(name: 'current_value')
  final double currentValue;
  @JsonKey(name: 'suggested_value')
  final double suggestedValue;
  final String reason;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const ProgressionPlanSuggestionModel({
    required this.id,
    required this.trainee,
    this.planSlot,
    required this.exerciseName,
    required this.suggestionType,
    required this.currentValue,
    required this.suggestedValue,
    required this.reason,
    this.status = 'pending',
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDismissed => status == 'dismissed';

  String get typeDisplay {
    switch (suggestionType) {
      case 'weight':
        return 'Weight';
      case 'reps':
        return 'Reps';
      case 'sets':
        return 'Sets';
      case 'rest':
        return 'Rest';
      default:
        return suggestionType;
    }
  }

  String get currentDisplay {
    if (suggestionType == 'reps' || suggestionType == 'sets') {
      return currentValue.toInt().toString();
    }
    if (suggestionType == 'rest') {
      return '${currentValue.toInt()}s';
    }
    return '${currentValue}lbs';
  }

  String get suggestedDisplay {
    if (suggestionType == 'reps' || suggestionType == 'sets') {
      return suggestedValue.toInt().toString();
    }
    if (suggestionType == 'rest') {
      return '${suggestedValue.toInt()}s';
    }
    return '${suggestedValue}lbs';
  }

  factory ProgressionPlanSuggestionModel.fromJson(Map<String, dynamic> json) =>
      _$ProgressionPlanSuggestionModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ProgressionPlanSuggestionModelToJson(this);
}
