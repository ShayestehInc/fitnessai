import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../workout_log/presentation/providers/workout_provider.dart';

/// Available rest durations in seconds.
const List<int> kRestDurationOptions = [30, 60, 90, 120, 180];

/// Default rest duration (seconds).
const int kDefaultRestDuration = 90;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Tracks completion state for a single set.
class TvSetState {
  final int setNumber;
  final bool completed;

  const TvSetState({required this.setNumber, this.completed = false});

  TvSetState copyWith({bool? completed}) =>
      TvSetState(setNumber: setNumber, completed: completed ?? this.completed);
}

/// Tracks completion state for an exercise in TV mode.
class TvExerciseState {
  final ProgramExercise exercise;
  final List<TvSetState> sets;

  const TvExerciseState({required this.exercise, required this.sets});

  bool get allSetsCompleted => sets.every((s) => s.completed);
  int get completedSetCount => sets.where((s) => s.completed).length;
}

/// Root state for TV mode.
class TvModeState {
  final List<TvExerciseState> exercises;
  final int currentExerciseIndex;
  final int restSecondsRemaining;
  final int restDurationSetting;
  final bool isResting;
  final bool isLoading;
  final bool workoutComplete;
  final Duration elapsed;
  final String? error;

  const TvModeState({
    this.exercises = const [],
    this.currentExerciseIndex = 0,
    this.restSecondsRemaining = 0,
    this.restDurationSetting = kDefaultRestDuration,
    this.isResting = false,
    this.isLoading = true,
    this.workoutComplete = false,
    this.elapsed = Duration.zero,
    this.error,
  });

  TvModeState copyWith({
    List<TvExerciseState>? exercises,
    int? currentExerciseIndex,
    int? restSecondsRemaining,
    int? restDurationSetting,
    bool? isResting,
    bool? isLoading,
    bool? workoutComplete,
    Duration? elapsed,
    String? error,
  }) {
    return TvModeState(
      exercises: exercises ?? this.exercises,
      currentExerciseIndex:
          currentExerciseIndex ?? this.currentExerciseIndex,
      restSecondsRemaining:
          restSecondsRemaining ?? this.restSecondsRemaining,
      restDurationSetting:
          restDurationSetting ?? this.restDurationSetting,
      isResting: isResting ?? this.isResting,
      isLoading: isLoading ?? this.isLoading,
      workoutComplete: workoutComplete ?? this.workoutComplete,
      elapsed: elapsed ?? this.elapsed,
      error: error,
    );
  }

  int get totalSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.length);

  int get completedSets =>
      exercises.fold(0, (sum, e) => sum + e.completedSetCount);

  int get totalExercises => exercises.length;

  int get completedExercises =>
      exercises.where((e) => e.allSetsCompleted).length;

  double get progressFraction =>
      totalSets > 0 ? completedSets / totalSets : 0.0;

  TvExerciseState? get currentExercise => currentExerciseIndex < exercises.length
      ? exercises[currentExerciseIndex]
      : null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TvModeNotifier extends StateNotifier<TvModeState> {
  TvModeNotifier() : super(const TvModeState());

  Timer? _restTimer;
  Timer? _elapsedTimer;
  final Stopwatch _stopwatch = Stopwatch();

  /// Initialize from today's workout exercises.
  void loadWorkout(List<ProgramExercise> programExercises) {
    if (programExercises.isEmpty) {
      state = const TvModeState(isLoading: false, error: 'No exercises');
      return;
    }

    final exercises = programExercises.map((pe) {
      final sets = List.generate(
        pe.targetSets,
        (i) => TvSetState(setNumber: i + 1),
      );
      return TvExerciseState(exercise: pe, sets: sets);
    }).toList();

    state = TvModeState(
      exercises: exercises,
      isLoading: false,
      restDurationSetting: state.restDurationSetting,
    );

    _startElapsedTimer();
  }

  void setError(String message) {
    state = TvModeState(isLoading: false, error: message);
  }

  /// Complete the next incomplete set of the current exercise.
  void completeSet() {
    if (state.workoutComplete || state.isResting) return;

    final exerciseIdx = state.currentExerciseIndex;
    if (exerciseIdx >= state.exercises.length) return;

    final exerciseState = state.exercises[exerciseIdx];
    final nextSetIdx =
        exerciseState.sets.indexWhere((s) => !s.completed);
    if (nextSetIdx == -1) return;

    // Mark set completed.
    final updatedSets = List<TvSetState>.from(exerciseState.sets);
    updatedSets[nextSetIdx] = updatedSets[nextSetIdx].copyWith(completed: true);

    final updatedExercise =
        TvExerciseState(exercise: exerciseState.exercise, sets: updatedSets);

    final updatedExercises = List<TvExerciseState>.from(state.exercises);
    updatedExercises[exerciseIdx] = updatedExercise;

    final allDone = updatedExercises.every((e) => e.allSetsCompleted);

    state = state.copyWith(
      exercises: updatedExercises,
      workoutComplete: allDone,
    );

    if (allDone) {
      _stopwatch.stop();
      _elapsedTimer?.cancel();
      return;
    }

    // Auto-advance to next exercise if all sets done.
    if (updatedExercise.allSetsCompleted) {
      _advanceToNextExercise();
    }

    // Start rest timer.
    _startRestTimer();
  }

  void _advanceToNextExercise() {
    final nextIdx = state.exercises.indexWhere(
      (e) => !e.allSetsCompleted,
      state.currentExerciseIndex + 1,
    );
    if (nextIdx != -1) {
      state = state.copyWith(currentExerciseIndex: nextIdx);
    }
  }

  void skipRest() {
    _restTimer?.cancel();
    state = state.copyWith(isResting: false, restSecondsRemaining: 0);
  }

  void setRestDuration(int seconds) {
    state = state.copyWith(restDurationSetting: seconds);
  }

  void jumpToExercise(int index) {
    if (index >= 0 && index < state.exercises.length) {
      state = state.copyWith(currentExerciseIndex: index);
    }
  }

  // ---- Timers ----

  void _startRestTimer() {
    _restTimer?.cancel();
    final duration = state.restDurationSetting;
    state = state.copyWith(isResting: true, restSecondsRemaining: duration);

    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.restSecondsRemaining - 1;
      if (remaining <= 0) {
        _restTimer?.cancel();
        state = state.copyWith(isResting: false, restSecondsRemaining: 0);
      } else {
        state = state.copyWith(restSecondsRemaining: remaining);
      }
    });
  }

  void _startElapsedTimer() {
    _stopwatch.start();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsed: _stopwatch.elapsed);
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _elapsedTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final tvModeProvider =
    StateNotifierProvider.autoDispose<TvModeNotifier, TvModeState>(
  (ref) => TvModeNotifier(),
);
