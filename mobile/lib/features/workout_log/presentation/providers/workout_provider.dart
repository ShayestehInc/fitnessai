import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/workout_models.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkoutRepository(apiClient);
});

final workoutStateProvider =
    StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return WorkoutNotifier(repository);
});

/// Represents a workout day in the program
class ProgramWorkoutDay {
  final int dayIndex;
  final String name;
  final bool isRestDay;
  final bool isToday;
  final bool isCompleted;
  final int exerciseCount;
  final int estimatedMinutes;
  final String? imageUrl;
  final List<ProgramExercise> exercises;

  const ProgramWorkoutDay({
    required this.dayIndex,
    required this.name,
    this.isRestDay = false,
    this.isToday = false,
    this.isCompleted = false,
    this.exerciseCount = 0,
    this.estimatedMinutes = 45,
    this.imageUrl,
    this.exercises = const [],
  });
}

/// Represents an exercise in the program
class ProgramExercise {
  final int exerciseId;
  final String name;
  final String muscleGroup;
  final int targetSets;
  final int targetReps;
  final int? restSeconds;
  final String? videoUrl;
  final String? imageUrl;
  final double? lastWeight;
  final int? lastReps;
  final String? notes;

  const ProgramExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.targetSets,
    required this.targetReps,
    this.restSeconds,
    this.videoUrl,
    this.imageUrl,
    this.lastWeight,
    this.lastReps,
    this.notes,
  });
}

/// Represents a week in the program
class ProgramWeekData {
  final int weekNumber;
  final String? title;
  final double completionPercentage;
  final bool isCurrentWeek;
  final List<ProgramWorkoutDay> workouts;

  const ProgramWeekData({
    required this.weekNumber,
    this.title,
    this.completionPercentage = 0.0,
    this.isCurrentWeek = false,
    this.workouts = const [],
  });
}

class WorkoutState {
  final DateTime selectedDate;
  final WorkoutSummary? dailySummary;
  final ProgramModel? activeProgram;
  final List<ProgramModel> programs;
  final List<ProgramWeekData> programWeeks;
  final int selectedWeekIndex;
  final int currentDayIndex;
  final bool isLoading;
  final String? error;
  final Map<String, LastSetData> exerciseHistory;

  WorkoutState({
    DateTime? selectedDate,
    this.dailySummary,
    this.activeProgram,
    this.programs = const [],
    this.programWeeks = const [],
    this.selectedWeekIndex = 0,
    this.currentDayIndex = 0,
    this.isLoading = false,
    this.error,
    this.exerciseHistory = const {},
  }) : selectedDate = selectedDate ?? DateTime.now();

  WorkoutState copyWith({
    DateTime? selectedDate,
    WorkoutSummary? dailySummary,
    ProgramModel? activeProgram,
    List<ProgramModel>? programs,
    List<ProgramWeekData>? programWeeks,
    int? selectedWeekIndex,
    int? currentDayIndex,
    bool? isLoading,
    String? error,
    Map<String, LastSetData>? exerciseHistory,
  }) {
    return WorkoutState(
      selectedDate: selectedDate ?? this.selectedDate,
      dailySummary: dailySummary ?? this.dailySummary,
      activeProgram: activeProgram ?? this.activeProgram,
      programs: programs ?? this.programs,
      programWeeks: programWeeks ?? this.programWeeks,
      selectedWeekIndex: selectedWeekIndex ?? this.selectedWeekIndex,
      currentDayIndex: currentDayIndex ?? this.currentDayIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      exerciseHistory: exerciseHistory ?? this.exerciseHistory,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (selected == today) {
      return 'Today';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (selected == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d, yyyy').format(selectedDate);
    }
  }

  String get dateParam => DateFormat('yyyy-MM-dd').format(selectedDate);

  ProgramWeekData? get selectedWeek =>
      selectedWeekIndex < programWeeks.length ? programWeeks[selectedWeekIndex] : null;

  ProgramWorkoutDay? get todaysWorkout {
    final week = selectedWeek;
    if (week == null) return null;
    return week.workouts.where((w) => w.isToday && !w.isRestDay).firstOrNull;
  }

  List<ProgramWorkoutDay> get upcomingWorkouts {
    final week = selectedWeek;
    if (week == null) return [];
    return week.workouts
        .where((w) => !w.isToday && !w.isRestDay && !w.isCompleted)
        .take(3)
        .toList();
  }
}

/// Stores last set data for an exercise
class LastSetData {
  final double weight;
  final int reps;
  final String unit;
  final DateTime loggedAt;

  const LastSetData({
    required this.weight,
    required this.reps,
    this.unit = 'lbs',
    required this.loggedAt,
  });
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final WorkoutRepository _repository;

  WorkoutNotifier(this._repository) : super(WorkoutState());

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);

    // Load workout summary and programs in parallel
    final results = await Future.wait([
      _repository.getDailyWorkoutSummary(state.dateParam),
      _repository.getPrograms(),
    ]);

    final summaryResult = results[0];
    final programsResult = results[1];

    ProgramModel? activeProgram;
    List<ProgramModel> programs = [];
    List<ProgramWeekData> programWeeks = [];

    if (programsResult['success'] == true) {
      programs = programsResult['programs'] as List<ProgramModel>;
      activeProgram = programs.isNotEmpty
          ? programs
              .cast<ProgramModel?>()
              .firstWhere((p) => p!.isActive, orElse: () => programs.first)
          : null;

      if (activeProgram != null) {
        programWeeks = _parseProgramWeeks(activeProgram);
      }
    }

    // Find which week and day is current
    int selectedWeekIndex = 0;
    int currentDayIndex = 0;
    if (programWeeks.isNotEmpty) {
      for (int i = 0; i < programWeeks.length; i++) {
        if (programWeeks[i].isCurrentWeek) {
          selectedWeekIndex = i;
          break;
        }
      }
    }

    state = state.copyWith(
      isLoading: false,
      dailySummary: summaryResult['success'] == true
          ? summaryResult['summary'] as WorkoutSummary
          : null,
      programs: programs,
      activeProgram: activeProgram,
      programWeeks: programWeeks,
      selectedWeekIndex: selectedWeekIndex,
      currentDayIndex: currentDayIndex,
    );
  }

  List<ProgramWeekData> _parseProgramWeeks(ProgramModel program) {
    final schedule = program.schedule;

    // Handle null or empty schedule
    if (schedule == null) return _generateSampleWeeks();

    // Determine the weeks list based on schedule format
    List<dynamic>? weeksList;

    if (schedule is List && schedule.isNotEmpty) {
      // New API format: schedule is directly a list of weeks
      weeksList = schedule;
    } else if (schedule is Map<String, dynamic> && schedule.isNotEmpty) {
      // Legacy format: schedule has a 'weeks' key
      if (schedule.containsKey('weeks')) {
        weeksList = schedule['weeks'] as List<dynamic>?;
      }
    }

    if (weeksList == null || weeksList.isEmpty) {
      return _generateSampleWeeks();
    }

    final List<ProgramWeekData> weeks = [];
    final now = DateTime.now();

    // Parse start date to calculate current week
    DateTime? startDate;
    try {
      startDate = DateTime.parse(program.startDate);
    } catch (_) {
      startDate = now;
    }

    final daysSinceStart = now.difference(startDate).inDays;
    final currentWeekNumber = (daysSinceStart / 7).floor() + 1;
    final currentDayOfWeek = daysSinceStart % 7;

    for (int i = 0; i < weeksList.length; i++) {
      final weekData = weeksList[i] as Map<String, dynamic>;
      final weekNumber = weekData['week_number'] as int? ?? (i + 1);
      final isCurrentWeek = weekNumber == currentWeekNumber;

      final days = (weekData['days'] as List<dynamic>?) ?? [];
      final workouts = <ProgramWorkoutDay>[];

      for (int d = 0; d < days.length; d++) {
        final dayData = days[d] as Map<String, dynamic>;
        final isRestDay = dayData['is_rest_day'] as bool? ?? false;
        final exercises = (dayData['exercises'] as List<dynamic>?) ?? [];
        final isToday = isCurrentWeek && d == currentDayOfWeek;

        workouts.add(ProgramWorkoutDay(
          dayIndex: d,
          name: dayData['name'] as String? ?? 'Day ${d + 1}',
          isRestDay: isRestDay,
          isToday: isToday,
          isCompleted: isCurrentWeek && d < currentDayOfWeek,
          exerciseCount: exercises.length,
          estimatedMinutes: _estimateWorkoutDuration(exercises.length),
          exercises: _parseExercises(exercises),
        ));
      }

      // Calculate completion percentage
      final completedWorkouts = workouts.where((w) => w.isCompleted && !w.isRestDay).length;
      final totalWorkouts = workouts.where((w) => !w.isRestDay).length;
      final completion = totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0.0;

      weeks.add(ProgramWeekData(
        weekNumber: weekNumber,
        title: weekData['title'] as String?,
        completionPercentage: completion,
        isCurrentWeek: isCurrentWeek,
        workouts: workouts,
      ));
    }

    return weeks.isEmpty ? _generateSampleWeeks() : weeks;
  }

  List<ProgramExercise> _parseExercises(List<dynamic> exercises) {
    return exercises.map((e) {
      final data = e as Map<String, dynamic>;
      return ProgramExercise(
        exerciseId: data['exercise_id'] as int? ?? 0,
        name: data['exercise_name'] as String? ?? 'Exercise',
        muscleGroup: data['muscle_group'] as String? ?? 'other',
        targetSets: data['sets'] as int? ?? 3,
        targetReps: data['reps'] as int? ?? 10,
        restSeconds: data['rest_seconds'] as int?,
        videoUrl: data['video_url'] as String?,
        imageUrl: data['image_url'] as String?,
        notes: data['notes'] as String?,
      );
    }).toList();
  }

  int _estimateWorkoutDuration(int exerciseCount) {
    // Roughly 5 minutes per exercise (including rest)
    return exerciseCount * 5 + 10; // Plus 10 for warmup
  }

  List<ProgramWeekData> _generateSampleWeeks() {
    // Generate sample data when no program is available
    final now = DateTime.now();
    final dayOfWeek = now.weekday - 1; // 0 = Monday

    return List.generate(4, (weekIndex) {
      final isCurrentWeek = weekIndex == 0;
      final workouts = [
        ProgramWorkoutDay(
          dayIndex: 0,
          name: 'Push Day',
          isToday: isCurrentWeek && dayOfWeek == 0,
          isCompleted: isCurrentWeek && dayOfWeek > 0,
          exerciseCount: 6,
          estimatedMinutes: 45,
          exercises: _getSampleExercises('push'),
        ),
        ProgramWorkoutDay(
          dayIndex: 1,
          name: 'Pull Day',
          isToday: isCurrentWeek && dayOfWeek == 1,
          isCompleted: isCurrentWeek && dayOfWeek > 1,
          exerciseCount: 6,
          estimatedMinutes: 45,
          exercises: _getSampleExercises('pull'),
        ),
        ProgramWorkoutDay(
          dayIndex: 2,
          name: 'Legs',
          isToday: isCurrentWeek && dayOfWeek == 2,
          isCompleted: isCurrentWeek && dayOfWeek > 2,
          exerciseCount: 5,
          estimatedMinutes: 50,
          exercises: _getSampleExercises('legs'),
        ),
        ProgramWorkoutDay(
          dayIndex: 3,
          name: 'Rest Day',
          isRestDay: true,
          isToday: isCurrentWeek && dayOfWeek == 3,
          isCompleted: isCurrentWeek && dayOfWeek > 3,
        ),
        ProgramWorkoutDay(
          dayIndex: 4,
          name: 'Upper Body',
          isToday: isCurrentWeek && dayOfWeek == 4,
          isCompleted: isCurrentWeek && dayOfWeek > 4,
          exerciseCount: 7,
          estimatedMinutes: 55,
          exercises: _getSampleExercises('upper'),
        ),
        ProgramWorkoutDay(
          dayIndex: 5,
          name: 'Lower Body',
          isToday: isCurrentWeek && dayOfWeek == 5,
          isCompleted: isCurrentWeek && dayOfWeek > 5,
          exerciseCount: 5,
          estimatedMinutes: 45,
          exercises: _getSampleExercises('lower'),
        ),
        ProgramWorkoutDay(
          dayIndex: 6,
          name: 'Rest Day',
          isRestDay: true,
          isToday: isCurrentWeek && dayOfWeek == 6,
          isCompleted: false,
        ),
      ];

      final completedWorkouts = workouts.where((w) => w.isCompleted && !w.isRestDay).length;
      final totalWorkouts = workouts.where((w) => !w.isRestDay).length;
      final completion = totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0.0;

      return ProgramWeekData(
        weekNumber: weekIndex + 1,
        completionPercentage: isCurrentWeek ? completion : (weekIndex == 0 ? 0.0 : 1.0),
        isCurrentWeek: isCurrentWeek,
        workouts: workouts,
      );
    });
  }

  List<ProgramExercise> _getSampleExercises(String type) {
    switch (type) {
      case 'push':
        return const [
          ProgramExercise(exerciseId: 1, name: 'Bench Press', muscleGroup: 'chest', targetSets: 4, targetReps: 8, lastWeight: 185, lastReps: 8),
          ProgramExercise(exerciseId: 2, name: 'Incline Dumbbell Press', muscleGroup: 'chest', targetSets: 3, targetReps: 10, lastWeight: 60, lastReps: 10),
          ProgramExercise(exerciseId: 3, name: 'Overhead Press', muscleGroup: 'shoulders', targetSets: 4, targetReps: 8, lastWeight: 95, lastReps: 8),
          ProgramExercise(exerciseId: 4, name: 'Lateral Raises', muscleGroup: 'shoulders', targetSets: 3, targetReps: 12, lastWeight: 20, lastReps: 12),
          ProgramExercise(exerciseId: 5, name: 'Tricep Pushdowns', muscleGroup: 'triceps', targetSets: 3, targetReps: 12, lastWeight: 50, lastReps: 12),
          ProgramExercise(exerciseId: 6, name: 'Dips', muscleGroup: 'triceps', targetSets: 3, targetReps: 10, lastWeight: 0, lastReps: 10),
        ];
      case 'pull':
        return const [
          ProgramExercise(exerciseId: 7, name: 'Deadlift', muscleGroup: 'back', targetSets: 4, targetReps: 5, lastWeight: 275, lastReps: 5),
          ProgramExercise(exerciseId: 8, name: 'Pull-ups', muscleGroup: 'back', targetSets: 4, targetReps: 8, lastWeight: 0, lastReps: 8),
          ProgramExercise(exerciseId: 9, name: 'Barbell Rows', muscleGroup: 'back', targetSets: 4, targetReps: 8, lastWeight: 135, lastReps: 8),
          ProgramExercise(exerciseId: 10, name: 'Face Pulls', muscleGroup: 'shoulders', targetSets: 3, targetReps: 15, lastWeight: 35, lastReps: 15),
          ProgramExercise(exerciseId: 11, name: 'Barbell Curls', muscleGroup: 'biceps', targetSets: 3, targetReps: 10, lastWeight: 65, lastReps: 10),
          ProgramExercise(exerciseId: 12, name: 'Hammer Curls', muscleGroup: 'biceps', targetSets: 3, targetReps: 12, lastWeight: 30, lastReps: 12),
        ];
      case 'legs':
        return const [
          ProgramExercise(exerciseId: 13, name: 'Squats', muscleGroup: 'legs', targetSets: 4, targetReps: 6, lastWeight: 225, lastReps: 6),
          ProgramExercise(exerciseId: 14, name: 'Romanian Deadlift', muscleGroup: 'legs', targetSets: 3, targetReps: 10, lastWeight: 155, lastReps: 10),
          ProgramExercise(exerciseId: 15, name: 'Leg Press', muscleGroup: 'legs', targetSets: 3, targetReps: 12, lastWeight: 360, lastReps: 12),
          ProgramExercise(exerciseId: 16, name: 'Leg Curls', muscleGroup: 'legs', targetSets: 3, targetReps: 12, lastWeight: 90, lastReps: 12),
          ProgramExercise(exerciseId: 17, name: 'Calf Raises', muscleGroup: 'legs', targetSets: 4, targetReps: 15, lastWeight: 180, lastReps: 15),
        ];
      case 'upper':
        return const [
          ProgramExercise(exerciseId: 1, name: 'Bench Press', muscleGroup: 'chest', targetSets: 4, targetReps: 8, lastWeight: 185, lastReps: 8),
          ProgramExercise(exerciseId: 8, name: 'Pull-ups', muscleGroup: 'back', targetSets: 4, targetReps: 8, lastWeight: 0, lastReps: 8),
          ProgramExercise(exerciseId: 3, name: 'Overhead Press', muscleGroup: 'shoulders', targetSets: 3, targetReps: 10, lastWeight: 95, lastReps: 10),
          ProgramExercise(exerciseId: 9, name: 'Barbell Rows', muscleGroup: 'back', targetSets: 3, targetReps: 10, lastWeight: 135, lastReps: 10),
          ProgramExercise(exerciseId: 2, name: 'Incline Dumbbell Press', muscleGroup: 'chest', targetSets: 3, targetReps: 12, lastWeight: 60, lastReps: 12),
          ProgramExercise(exerciseId: 11, name: 'Barbell Curls', muscleGroup: 'biceps', targetSets: 3, targetReps: 10, lastWeight: 65, lastReps: 10),
          ProgramExercise(exerciseId: 5, name: 'Tricep Pushdowns', muscleGroup: 'triceps', targetSets: 3, targetReps: 12, lastWeight: 50, lastReps: 12),
        ];
      case 'lower':
        return const [
          ProgramExercise(exerciseId: 13, name: 'Squats', muscleGroup: 'legs', targetSets: 4, targetReps: 8, lastWeight: 225, lastReps: 8),
          ProgramExercise(exerciseId: 14, name: 'Romanian Deadlift', muscleGroup: 'legs', targetSets: 3, targetReps: 10, lastWeight: 155, lastReps: 10),
          ProgramExercise(exerciseId: 18, name: 'Bulgarian Split Squats', muscleGroup: 'legs', targetSets: 3, targetReps: 10, lastWeight: 50, lastReps: 10),
          ProgramExercise(exerciseId: 16, name: 'Leg Curls', muscleGroup: 'legs', targetSets: 3, targetReps: 12, lastWeight: 90, lastReps: 12),
          ProgramExercise(exerciseId: 17, name: 'Calf Raises', muscleGroup: 'legs', targetSets: 4, targetReps: 15, lastWeight: 180, lastReps: 15),
        ];
      default:
        return [];
    }
  }

  Future<void> refreshDailySummary() async {
    state = state.copyWith(isLoading: true, error: null);

    final result =
        await _repository.getDailyWorkoutSummary(state.dateParam);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        dailySummary: result['summary'] as WorkoutSummary,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  void selectWeek(int index) {
    if (index >= 0 && index < state.programWeeks.length) {
      state = state.copyWith(selectedWeekIndex: index);
    }
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    refreshDailySummary();
  }

  void goToPreviousDay() {
    selectDate(state.selectedDate.subtract(const Duration(days: 1)));
  }

  void goToNextDay() {
    selectDate(state.selectedDate.add(const Duration(days: 1)));
  }

  void goToToday() {
    selectDate(DateTime.now());
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
