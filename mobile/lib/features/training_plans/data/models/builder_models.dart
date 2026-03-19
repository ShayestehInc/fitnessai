/// Models for the dual-mode program builder (Quick Build + Advanced Builder).

class StepExplanation {
  final String stepName;
  final int stepNumber;
  final Map<String, dynamic> recommendation;
  final List<Map<String, dynamic>> alternatives;
  final String why;

  const StepExplanation({
    required this.stepName,
    required this.stepNumber,
    required this.recommendation,
    this.alternatives = const [],
    required this.why,
  });

  factory StepExplanation.fromJson(Map<String, dynamic> json) {
    return StepExplanation(
      stepName: json['step_name'] as String? ?? '',
      stepNumber: (json['step_number'] as num?)?.toInt() ?? 0,
      recommendation: json['recommendation'] as Map<String, dynamic>? ?? {},
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      why: json['why'] as String? ?? '',
    );
  }
}

class QuickBuildResult {
  final String planId;
  final String planName;
  final int weeksCount;
  final int sessionsCount;
  final int slotsCount;
  final List<String> decisionLogIds;
  final String summary;
  final List<StepExplanation> stepExplanations;

  const QuickBuildResult({
    required this.planId,
    required this.planName,
    required this.weeksCount,
    required this.sessionsCount,
    required this.slotsCount,
    this.decisionLogIds = const [],
    required this.summary,
    this.stepExplanations = const [],
  });

  factory QuickBuildResult.fromJson(Map<String, dynamic> json) {
    return QuickBuildResult(
      planId: json['plan_id'] as String? ?? '',
      planName: json['plan_name'] as String? ?? '',
      weeksCount: (json['weeks_count'] as num?)?.toInt() ?? 0,
      sessionsCount: (json['sessions_count'] as num?)?.toInt() ?? 0,
      slotsCount: (json['slots_count'] as num?)?.toInt() ?? 0,
      decisionLogIds: (json['decision_log_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      summary: json['summary'] as String? ?? '',
      stepExplanations: (json['step_explanations'] as List<dynamic>?)
              ?.map(
                  (e) => StepExplanation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BuilderStepResult {
  final String planId;
  final String currentStep;
  final int currentStepNumber;
  final int totalSteps;
  final Map<String, dynamic> recommendation;
  final List<Map<String, dynamic>> alternatives;
  final String why;
  final Map<String, dynamic> preview;
  final bool isComplete;

  const BuilderStepResult({
    required this.planId,
    required this.currentStep,
    required this.currentStepNumber,
    required this.totalSteps,
    required this.recommendation,
    this.alternatives = const [],
    required this.why,
    this.preview = const {},
    this.isComplete = false,
  });

  factory BuilderStepResult.fromJson(Map<String, dynamic> json) {
    return BuilderStepResult(
      planId: json['plan_id'] as String? ?? '',
      currentStep: json['current_step'] as String? ?? '',
      currentStepNumber: (json['current_step_number'] as num?)?.toInt() ?? 0,
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 9,
      recommendation: json['recommendation'] as Map<String, dynamic>? ?? {},
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      why: json['why'] as String? ?? '',
      preview: json['preview'] as Map<String, dynamic>? ?? {},
      isComplete: json['is_complete'] as bool? ?? false,
    );
  }
}

/// Brief data for starting a builder session.
class BuilderBrief {
  final int traineeId;
  final String goal;
  final int daysPerWeek;
  final String difficulty;
  final int sessionLengthMinutes;
  final List<String> equipment;
  final List<String> injuries;
  final String style;
  final List<String> priorities;
  final List<String> dislikes;
  final int? durationWeeks;
  final List<int> trainingDayIndices;

  const BuilderBrief({
    required this.traineeId,
    required this.goal,
    required this.daysPerWeek,
    this.difficulty = 'intermediate',
    this.sessionLengthMinutes = 60,
    this.equipment = const [],
    this.injuries = const [],
    this.style = '',
    this.priorities = const [],
    this.dislikes = const [],
    this.durationWeeks,
    this.trainingDayIndices = const [],
  });

  Map<String, dynamic> toJson() => {
        'trainee_id': traineeId,
        'goal': goal,
        'days_per_week': daysPerWeek,
        'difficulty': difficulty,
        'session_length_minutes': sessionLengthMinutes,
        'equipment': equipment,
        'injuries': injuries,
        'style': style,
        'priorities': priorities,
        'dislikes': dislikes,
        if (durationWeeks != null) 'duration_weeks': durationWeeks,
        'training_day_indices': trainingDayIndices,
      };
}
