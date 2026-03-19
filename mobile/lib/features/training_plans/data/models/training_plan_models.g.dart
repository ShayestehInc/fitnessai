// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_plan_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingPlanModel _$TrainingPlanModelFromJson(Map<String, dynamic> json) =>
    TrainingPlanModel(
      id: json['id'] as String,
      trainee: json['trainee'],
      name: json['name'] as String?,
      description: json['description'] as String?,
      goal: json['goal'] as String,
      status: json['status'] as String,
      difficulty: json['difficulty'] as String?,
      splitTemplate: json['split_template'] as String?,
      splitTemplateName: json['split_template_name'] as String?,
      durationWeeks: (json['duration_weeks'] as num?)?.toInt(),
      weeksCount: (json['weeks_count'] as num?)?.toInt() ?? 0,
      buildMode: json['build_mode'] as String?,
      createdAt: json['created_at'] as String,
      weeks: (json['weeks'] as List<dynamic>?)
          ?.map((e) => PlanWeekModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrainingPlanModelToJson(TrainingPlanModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trainee': instance.trainee,
      'name': instance.name,
      'description': instance.description,
      'goal': instance.goal,
      'status': instance.status,
      'difficulty': instance.difficulty,
      'split_template': instance.splitTemplate,
      'split_template_name': instance.splitTemplateName,
      'duration_weeks': instance.durationWeeks,
      'weeks_count': instance.weeksCount,
      'build_mode': instance.buildMode,
      'created_at': instance.createdAt,
      'weeks': instance.weeks,
    };

PlanWeekModel _$PlanWeekModelFromJson(Map<String, dynamic> json) =>
    PlanWeekModel(
      id: json['id'] as String,
      weekNumber: (json['week_number'] as num).toInt(),
      isDeload: json['is_deload'] as bool? ?? false,
      intensityModifier: json['intensity_modifier'] == null
          ? 1.0
          : PlanWeekModel._intensityFromJson(json['intensity_modifier']),
      volumeModifier: json['volume_modifier'] == null
          ? 1.0
          : PlanWeekModel._volumeFromJson(json['volume_modifier']),
      phase: json['phase'] as String?,
      sessions: (json['sessions'] as List<dynamic>?)
          ?.map((e) => PlanSessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlanWeekModelToJson(PlanWeekModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'week_number': instance.weekNumber,
      'is_deload': instance.isDeload,
      'intensity_modifier': instance.intensityModifier,
      'volume_modifier': instance.volumeModifier,
      'phase': instance.phase,
      'sessions': instance.sessions,
    };

PlanSessionModel _$PlanSessionModelFromJson(Map<String, dynamic> json) =>
    PlanSessionModel(
      id: json['id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      label: json['label'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      dayRole: json['day_role'] as String?,
      sessionFamily: json['session_family'] as String?,
      dayStress: json['day_stress'] as String?,
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt(),
      slots: (json['slots'] as List<dynamic>?)
          ?.map((e) => PlanSlotModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlanSessionModelToJson(PlanSessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day_of_week': instance.dayOfWeek,
      'label': instance.label,
      'order': instance.order,
      'day_role': instance.dayRole,
      'session_family': instance.sessionFamily,
      'day_stress': instance.dayStress,
      'estimated_duration_minutes': instance.estimatedDurationMinutes,
      'slots': instance.slots,
    };

PlanSlotModel _$PlanSlotModelFromJson(Map<String, dynamic> json) =>
    PlanSlotModel(
      id: json['id'] as String,
      exercise: (json['exercise'] as num?)?.toInt(),
      exerciseName: json['exercise_name'] as String?,
      slotRole: json['slot_role'] as String,
      sets: (json['sets'] as num).toInt(),
      repsMin: (json['reps_min'] as num).toInt(),
      repsMax: (json['reps_max'] as num).toInt(),
      restSeconds: (json['rest_seconds'] as num?)?.toInt() ?? 60,
      setStructureModality: json['set_structure_modality'] as String?,
      modalityName: json['modality_name'] as String?,
      modalityDetails: json['modality_details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PlanSlotModelToJson(PlanSlotModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exercise': instance.exercise,
      'exercise_name': instance.exerciseName,
      'slot_role': instance.slotRole,
      'sets': instance.sets,
      'reps_min': instance.repsMin,
      'reps_max': instance.repsMax,
      'rest_seconds': instance.restSeconds,
      'set_structure_modality': instance.setStructureModality,
      'modality_name': instance.modalityName,
      'modality_details': instance.modalityDetails,
    };

SplitTemplateModel _$SplitTemplateModelFromJson(Map<String, dynamic> json) =>
    SplitTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      daysPerWeek: (json['days_per_week'] as num).toInt(),
      goalType: json['goal_type'] as String,
      isSystem: json['is_system'] as bool? ?? false,
      sessionDefinitions: json['session_definitions'] as List<dynamic>?,
    );

Map<String, dynamic> _$SplitTemplateModelToJson(SplitTemplateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'days_per_week': instance.daysPerWeek,
      'goal_type': instance.goalType,
      'is_system': instance.isSystem,
      'session_definitions': instance.sessionDefinitions,
    };

ModalityModel _$ModalityModelFromJson(Map<String, dynamic> json) =>
    ModalityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      volumeMultiplier: (json['volume_multiplier'] as num?)?.toDouble() ?? 1.0,
      guardrails: json['guardrails'] as Map<String, dynamic>?,
      useWhen: json['use_when'] as String?,
      avoidWhen: json['avoid_when'] as String?,
    );

Map<String, dynamic> _$ModalityModelToJson(ModalityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'volume_multiplier': instance.volumeMultiplier,
      'guardrails': instance.guardrails,
      'use_when': instance.useWhen,
      'avoid_when': instance.avoidWhen,
    };
