/// Represents a single exercise within a workout
class WorkoutExercise {
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int sets;
  final int reps;
  final int? restSeconds;
  final String? notes;

  const WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    this.restSeconds,
    this.notes,
  });

  WorkoutExercise copyWith({
    int? exerciseId,
    String? exerciseName,
    String? muscleGroup,
    int? sets,
    int? reps,
    int? restSeconds,
    String? notes,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'muscle_group': muscleGroup,
      'sets': sets,
      'reps': reps,
      'rest_seconds': restSeconds,
      'notes': notes,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exercise_id'] as int,
      exerciseName: json['exercise_name'] as String,
      muscleGroup: json['muscle_group'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      restSeconds: json['rest_seconds'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

/// Represents a single workout day
class WorkoutDay {
  final String name;
  final bool isRestDay;
  final List<WorkoutExercise> exercises;

  const WorkoutDay({
    required this.name,
    required this.isRestDay,
    required this.exercises,
  });

  WorkoutDay copyWith({
    String? name,
    bool? isRestDay,
    List<WorkoutExercise>? exercises,
  }) {
    return WorkoutDay(
      name: name ?? this.name,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'is_rest_day': isRestDay,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      name: json['name'] as String,
      isRestDay: json['is_rest_day'] as bool? ?? false,
      exercises: (json['exercises'] as List?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
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
      weekNumber: json['week_number'] as int,
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
