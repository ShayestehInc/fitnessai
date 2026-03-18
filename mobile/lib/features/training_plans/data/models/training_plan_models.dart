import 'package:json_annotation/json_annotation.dart';

part 'training_plan_models.g.dart';

@JsonSerializable()
class TrainingPlanModel {
  final int id;
  final int trainee;
  final String goal;
  final String status;
  @JsonKey(name: 'split_template')
  final int? splitTemplate;
  @JsonKey(name: 'split_template_name')
  final String? splitTemplateName;
  @JsonKey(name: 'weeks_count')
  final int weeksCount;
  @JsonKey(name: 'created_at')
  final String createdAt;
  final List<PlanWeekModel>? weeks;

  const TrainingPlanModel({
    required this.id,
    required this.trainee,
    required this.goal,
    required this.status,
    this.splitTemplate,
    this.splitTemplateName,
    this.weeksCount = 0,
    required this.createdAt,
    this.weeks,
  });

  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';
  bool get isCompleted => status == 'completed';
  bool get isArchived => status == 'archived';

  factory TrainingPlanModel.fromJson(Map<String, dynamic> json) =>
      _$TrainingPlanModelFromJson(json);

  Map<String, dynamic> toJson() => _$TrainingPlanModelToJson(this);
}

@JsonSerializable()
class PlanWeekModel {
  final int id;
  @JsonKey(name: 'week_number')
  final int weekNumber;
  @JsonKey(name: 'is_deload')
  final bool isDeload;
  @JsonKey(name: 'intensity_modifier')
  final double intensityModifier;
  @JsonKey(name: 'volume_modifier')
  final double volumeModifier;
  final List<PlanSessionModel>? sessions;

  const PlanWeekModel({
    required this.id,
    required this.weekNumber,
    this.isDeload = false,
    this.intensityModifier = 1.0,
    this.volumeModifier = 1.0,
    this.sessions,
  });

  int get sessionCount => sessions?.length ?? 0;

  factory PlanWeekModel.fromJson(Map<String, dynamic> json) =>
      _$PlanWeekModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlanWeekModelToJson(this);
}

@JsonSerializable()
class PlanSessionModel {
  final int id;
  @JsonKey(name: 'day_of_week')
  final int dayOfWeek;
  final String label;
  final int order;
  final List<PlanSlotModel>? slots;

  const PlanSessionModel({
    required this.id,
    required this.dayOfWeek,
    required this.label,
    this.order = 0,
    this.slots,
  });

  int get slotCount => slots?.length ?? 0;

  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return 'Day $dayOfWeek';
  }

  factory PlanSessionModel.fromJson(Map<String, dynamic> json) =>
      _$PlanSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlanSessionModelToJson(this);
}

@JsonSerializable()
class PlanSlotModel {
  final int id;
  final int? exercise;
  @JsonKey(name: 'exercise_name')
  final String? exerciseName;
  @JsonKey(name: 'slot_role')
  final String slotRole;
  final int sets;
  @JsonKey(name: 'reps_min')
  final int repsMin;
  @JsonKey(name: 'reps_max')
  final int repsMax;
  @JsonKey(name: 'rest_seconds')
  final int restSeconds;
  @JsonKey(name: 'set_structure_modality')
  final int? setStructureModality;
  @JsonKey(name: 'modality_name')
  final String? modalityName;
  @JsonKey(name: 'modality_details')
  final Map<String, dynamic>? modalityDetails;

  const PlanSlotModel({
    required this.id,
    this.exercise,
    this.exerciseName,
    required this.slotRole,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    this.restSeconds = 60,
    this.setStructureModality,
    this.modalityName,
    this.modalityDetails,
  });

  String get repsDisplay {
    if (repsMin == repsMax) {
      return '$repsMin';
    }
    return '$repsMin-$repsMax';
  }

  String get restDisplay {
    if (restSeconds >= 60) {
      final minutes = restSeconds ~/ 60;
      final seconds = restSeconds % 60;
      if (seconds == 0) {
        return '${minutes}m';
      }
      return '${minutes}m ${seconds}s';
    }
    return '${restSeconds}s';
  }

  String get roleDisplay {
    switch (slotRole) {
      case 'primary_compound':
        return 'Primary';
      case 'secondary_compound':
        return 'Secondary';
      case 'accessory':
        return 'Accessory';
      case 'isolation':
        return 'Isolation';
      default:
        return slotRole;
    }
  }

  factory PlanSlotModel.fromJson(Map<String, dynamic> json) =>
      _$PlanSlotModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlanSlotModelToJson(this);
}

@JsonSerializable()
class SplitTemplateModel {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'days_per_week')
  final int daysPerWeek;
  @JsonKey(name: 'goal_type')
  final String goalType;
  @JsonKey(name: 'is_system')
  final bool isSystem;
  @JsonKey(name: 'session_definitions')
  final List<dynamic>? sessionDefinitions;

  const SplitTemplateModel({
    required this.id,
    required this.name,
    this.description,
    required this.daysPerWeek,
    required this.goalType,
    this.isSystem = false,
    this.sessionDefinitions,
  });

  factory SplitTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$SplitTemplateModelFromJson(json);

  Map<String, dynamic> toJson() => _$SplitTemplateModelToJson(this);
}

@JsonSerializable()
class ModalityModel {
  final int id;
  final String name;
  final String slug;
  @JsonKey(name: 'volume_multiplier')
  final double volumeMultiplier;
  final Map<String, dynamic>? guardrails;
  @JsonKey(name: 'use_when')
  final String? useWhen;
  @JsonKey(name: 'avoid_when')
  final String? avoidWhen;

  const ModalityModel({
    required this.id,
    required this.name,
    required this.slug,
    this.volumeMultiplier = 1.0,
    this.guardrails,
    this.useWhen,
    this.avoidWhen,
  });

  factory ModalityModel.fromJson(Map<String, dynamic> json) =>
      _$ModalityModelFromJson(json);

  Map<String, dynamic> toJson() => _$ModalityModelToJson(this);
}
