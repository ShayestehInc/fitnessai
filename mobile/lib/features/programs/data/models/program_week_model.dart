/// Represents a single exercise within a workout
class WorkoutExercise {
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int sets;
  /// Reps stored as a string to support ranges like "8-10" from the
  /// smart program generator as well as fixed values like "12".
  final String reps;
  final int? restSeconds;
  final String? notes;
  final String? supersetGroupId; // Exercises with same ID are in a superset

  // v6.5 fields — populated by the AI generator, null for legacy programs
  final String? slotRole; // primary_compound, secondary_compound, accessory, isolation
  final String? setStructure; // straight_sets, drop_sets, supersets, myo_reps, etc.
  final String? tempo; // E-P-C-P format e.g. "2-0-1-0"
  final int? intensityTargetPct; // Target %TM e.g. 75
  final String? selectionReason; // AI explanation for why this exercise was chosen
  final Map<String, dynamic>? modalityDetails; // Drop %, cluster reps, myo-rep targets, etc.

  const WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    this.restSeconds,
    this.notes,
    this.supersetGroupId,
    this.slotRole,
    this.setStructure,
    this.tempo,
    this.intensityTargetPct,
    this.selectionReason,
    this.modalityDetails,
  });

  WorkoutExercise copyWith({
    int? exerciseId,
    String? exerciseName,
    String? muscleGroup,
    int? sets,
    String? reps,
    int? restSeconds,
    String? notes,
    String? supersetGroupId,
    bool clearSupersetGroup = false,
    String? slotRole,
    String? setStructure,
    String? tempo,
    int? intensityTargetPct,
    String? selectionReason,
    Map<String, dynamic>? modalityDetails,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      supersetGroupId: clearSupersetGroup ? null : (supersetGroupId ?? this.supersetGroupId),
      slotRole: slotRole ?? this.slotRole,
      setStructure: setStructure ?? this.setStructure,
      tempo: tempo ?? this.tempo,
      intensityTargetPct: intensityTargetPct ?? this.intensityTargetPct,
      selectionReason: selectionReason ?? this.selectionReason,
      modalityDetails: modalityDetails ?? this.modalityDetails,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'muscle_group': muscleGroup,
      'sets': sets,
      'reps': reps,
      'rest_seconds': restSeconds,
      'notes': notes,
      'superset_group_id': supersetGroupId,
    };
    // Include v6.5 fields only when present
    if (slotRole != null) json['slot_role'] = slotRole;
    if (setStructure != null) json['set_structure'] = setStructure;
    if (tempo != null) json['tempo'] = tempo;
    if (intensityTargetPct != null) json['intensity_target_pct'] = intensityTargetPct;
    if (selectionReason != null) json['selection_reason'] = selectionReason;
    if (modalityDetails != null) json['modality_details'] = modalityDetails;
    return json;
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    // reps can be an int (legacy / manual) or a String range ("8-10")
    final rawReps = json['reps'];
    final String parsedReps;
    if (rawReps is int) {
      parsedReps = rawReps.toString();
    } else if (rawReps is String) {
      parsedReps = rawReps;
    } else {
      parsedReps = '10';
    }

    return WorkoutExercise(
      exerciseId: (json['exercise_id'] as int?) ?? 0,
      exerciseName: (json['exercise_name'] as String?) ?? 'Unknown Exercise',
      muscleGroup: (json['muscle_group'] as String?) ?? 'other',
      sets: (json['sets'] as int?) ?? 3,
      reps: parsedReps,
      restSeconds: json['rest_seconds'] as int?,
      notes: json['notes'] as String?,
      supersetGroupId: json['superset_group_id'] as String?,
      slotRole: json['slot_role'] as String?,
      setStructure: json['set_structure'] as String?,
      tempo: json['tempo'] as String?,
      intensityTargetPct: json['intensity_target_pct'] as int?,
      selectionReason: json['selection_reason'] as String?,
      modalityDetails: json['modality_details'] != null
          ? Map<String, dynamic>.from(json['modality_details'] as Map)
          : null,
    );
  }

  bool get isInSuperset => supersetGroupId != null;

  /// Human-readable slot role label
  String get slotRoleLabel {
    switch (slotRole) {
      case 'primary_compound': return 'Primary';
      case 'secondary_compound': return 'Secondary';
      case 'accessory': return 'Accessory';
      case 'isolation': return 'Isolation';
      default: return '';
    }
  }

  /// Human-readable set structure label
  String get setStructureLabel {
    switch (setStructure) {
      case 'straight_sets': return 'Straight Sets';
      case 'drop_sets': return 'Drop Sets';
      case 'supersets': return 'Supersets';
      case 'myo_reps': return 'Myo-Reps';
      case 'controlled_eccentrics': return 'Controlled Eccentrics';
      case 'down_sets': return 'Down Sets';
      case 'giant_sets': return 'Giant Sets';
      case 'rest_pause': return 'Rest-Pause';
      case 'cluster_sets': return 'Cluster Sets';
      case 'circuit': return 'Circuit';
      case 'occlusion': return 'Occlusion';
      default: return setStructure?.replaceAll('_', ' ') ?? '';
    }
  }
}

/// Represents a single workout day
class WorkoutDay {
  final String name;
  final bool isRestDay;
  final List<WorkoutExercise> exercises;
  final List<String> sessionRoleLabels; // v6.5: e.g. ["heavy upper", "push hypertrophy"]

  const WorkoutDay({
    required this.name,
    required this.isRestDay,
    required this.exercises,
    this.sessionRoleLabels = const [],
  });

  WorkoutDay copyWith({
    String? name,
    bool? isRestDay,
    List<WorkoutExercise>? exercises,
    List<String>? sessionRoleLabels,
  }) {
    return WorkoutDay(
      name: name ?? this.name,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
      sessionRoleLabels: sessionRoleLabels ?? this.sessionRoleLabels,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'is_rest_day': isRestDay,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
    if (sessionRoleLabels.isNotEmpty) {
      json['session_role_labels'] = sessionRoleLabels;
    }
    return json;
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      name: (json['name'] as String?) ?? 'Workout',
      isRestDay: json['is_rest_day'] as bool? ?? false,
      exercises: (json['exercises'] as List?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sessionRoleLabels: (json['session_role_labels'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Represents a single week in the program
class ProgramWeek {
  final int weekNumber;
  final String? title;
  final String? notes;
  final bool isDeload;
  final double intensityModifier; // 1.0 = normal, 0.5 = deload
  final double volumeModifier;
  final List<WorkoutDay> days;

  const ProgramWeek({
    required this.weekNumber,
    this.title,
    this.notes,
    this.isDeload = false,
    this.intensityModifier = 1.0,
    this.volumeModifier = 1.0,
    required this.days,
  });

  ProgramWeek copyWith({
    int? weekNumber,
    String? title,
    String? notes,
    bool? isDeload,
    double? intensityModifier,
    double? volumeModifier,
    List<WorkoutDay>? days,
  }) {
    return ProgramWeek(
      weekNumber: weekNumber ?? this.weekNumber,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isDeload: isDeload ?? this.isDeload,
      intensityModifier: intensityModifier ?? this.intensityModifier,
      volumeModifier: volumeModifier ?? this.volumeModifier,
      days: days ?? this.days,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_number': weekNumber,
      'title': title,
      'notes': notes,
      'is_deload': isDeload,
      'intensity_modifier': intensityModifier,
      'volume_modifier': volumeModifier,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }

  factory ProgramWeek.fromJson(Map<String, dynamic> json) {
    return ProgramWeek(
      weekNumber: (json['week_number'] as int?) ?? 1,
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      isDeload: json['is_deload'] as bool? ?? false,
      intensityModifier: (json['intensity_modifier'] as num?)?.toDouble() ?? 1.0,
      volumeModifier: (json['volume_modifier'] as num?)?.toDouble() ?? 1.0,
      days: (json['days'] as List?)
              ?.map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  int get totalWorkoutDays => days.where((d) => !d.isRestDay).length;
  int get totalExercises => days.fold(0, (sum, day) => sum + day.exercises.length);
  int get totalSets => days.fold(0, (sum, day) => sum + day.exercises.fold(0, (s, e) => s + e.sets));
}

/// Full program builder state
class ProgramBuilderState {
  final String name;
  final String? description;
  final String difficulty;
  final String goal;
  final int durationWeeks;
  final List<ProgramWeek> weeks;

  const ProgramBuilderState({
    required this.name,
    this.description,
    required this.difficulty,
    required this.goal,
    required this.durationWeeks,
    required this.weeks,
  });

  ProgramBuilderState copyWith({
    String? name,
    String? description,
    String? difficulty,
    String? goal,
    int? durationWeeks,
    List<ProgramWeek>? weeks,
  }) {
    return ProgramBuilderState(
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      goal: goal ?? this.goal,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      weeks: weeks ?? this.weeks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'difficulty_level': difficulty,
      'goal_type': goal,
      'duration_weeks': durationWeeks,
      'weeks': weeks.map((w) => w.toJson()).toList(),
    };
  }
}
