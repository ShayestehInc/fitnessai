import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../workout_log/presentation/providers/workout_provider.dart';
import '../providers/tv_mode_provider.dart';
import '../widgets/tv_exercise_card.dart';
import '../widgets/tv_progress_bar.dart';
import '../widgets/tv_rest_timer.dart';
import '../widgets/tv_workout_header.dart';

/// Full-screen TV Mode gym display.
///
/// Loads today's workout from the active program and displays it
/// in a large, high-contrast format suitable for gym TVs/tablets.
/// Keeps the screen awake while active.
class TvModeScreen extends ConsumerStatefulWidget {
  const TvModeScreen({super.key});

  @override
  ConsumerState<TvModeScreen> createState() => _TvModeScreenState();
}

class _TvModeScreenState extends ConsumerState<TvModeScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // Use landscape-preferred but don't force it.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    // Immersive mode for TV-like display.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _loadWorkout();
  }

  void _loadWorkout() {
    final workoutState = ref.read(workoutStateProvider);

    if (workoutState.isLoading) {
      // Wait for workout provider to load.
      Future.microtask(() {
        ref.read(workoutStateProvider.notifier).loadInitialData().then((_) {
          if (mounted) _initFromWorkoutState();
        });
      });
    } else {
      _initFromWorkoutState();
    }
  }

  void _initFromWorkoutState() {
    final workoutState = ref.read(workoutStateProvider);
    final tvNotifier = ref.read(tvModeProvider.notifier);

    final todaysWorkout = workoutState.todaysWorkout;
    if (todaysWorkout == null || todaysWorkout.exercises.isEmpty) {
      tvNotifier.setError(_resolveEmptyReason(workoutState));
      return;
    }

    tvNotifier.loadWorkout(todaysWorkout.exercises);
  }

  String _resolveEmptyReason(WorkoutState workoutState) {
    if (workoutState.activeProgram == null) {
      return 'no_program';
    }
    final week = workoutState.selectedWeek;
    if (week == null) return 'no_workout';
    final todayWorkout = week.workouts
        .where((w) => w.isToday)
        .firstOrNull;
    if (todayWorkout != null && todayWorkout.isRestDay) {
      return 'rest_day';
    }
    return 'no_workout';
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleExit() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tvState = ref.watch(tvModeProvider);
    final workoutState = ref.watch(workoutStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      body: SafeArea(
        child: tvState.isLoading
            ? _buildLoading()
            : tvState.error != null
                ? _buildEmptyOrError(tvState.error!, workoutState)
                : tvState.workoutComplete
                    ? _buildComplete(tvState)
                    : _buildWorkoutView(tvState, workoutState),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppTheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading workout...',
            style: TextStyle(
              fontSize: 24,
              color: AppTheme.zinc400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrError(String reason, WorkoutState workoutState) {
    final IconData icon;
    final String title;
    final String subtitle;

    switch (reason) {
      case 'no_program':
        icon = Icons.fitness_center_outlined;
        title = 'No Program Assigned';
        subtitle = 'Ask your trainer to assign a workout program.';
      case 'rest_day':
        icon = Icons.self_improvement_outlined;
        title = 'Rest Day';
        subtitle = _buildNextWorkoutHint(workoutState);
      default:
        icon = Icons.event_busy_outlined;
        title = 'No Workout Today';
        subtitle = 'Check your program for upcoming workouts.';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppTheme.zinc800,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: AppTheme.zinc400),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 20, color: AppTheme.zinc400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildExitButton(),
        ],
      ),
    );
  }

  String _buildNextWorkoutHint(WorkoutState workoutState) {
    final week = workoutState.selectedWeek;
    if (week == null) return 'Enjoy your recovery!';
    final nextWorkout = week.workouts
        .where((w) => !w.isToday && !w.isRestDay && !w.isCompleted)
        .firstOrNull;
    if (nextWorkout != null) {
      return 'Next up: ${nextWorkout.name} (${nextWorkout.exerciseCount} exercises)';
    }
    return 'Enjoy your recovery!';
  }

  Widget _buildComplete(TvModeState tvState) {
    final minutes = tvState.elapsed.inMinutes;
    final seconds = tvState.elapsed.inSeconds.remainder(60);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 96,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(height: 24),
          const Text(
            'Workout Complete!',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${tvState.totalExercises} exercises \u2022 ${tvState.totalSets} sets \u2022 ${minutes}m ${seconds}s',
            style: const TextStyle(
              fontSize: 24,
              color: AppTheme.zinc300,
            ),
          ),
          const SizedBox(height: 48),
          _buildExitButton(),
        ],
      ),
    );
  }

  Widget _buildExitButton() {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _handleExit,
        icon: const Icon(Icons.arrow_back_rounded, size: 24),
        label: const Text(
          'EXIT TV MODE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.zinc700,
          foregroundColor: AppTheme.foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutView(TvModeState tvState, WorkoutState workoutState) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          TvWorkoutHeader(
            programName: workoutState.activeProgram?.name ?? 'Workout',
            dayName: workoutState.todaysWorkout?.name ?? 'Today',
            elapsed: tvState.elapsed,
            onExit: _handleExit,
          ),
          const SizedBox(height: 16),
          // Progress bar
          TvProgressBar(
            fraction: tvState.progressFraction,
            completedExercises: tvState.completedExercises,
            totalExercises: tvState.totalExercises,
          ),
          const SizedBox(height: 16),
          // Main content: exercises + rest timer
          Expanded(child: _buildMainContent(tvState)),
          // Complete set button
          if (!tvState.isResting && !tvState.workoutComplete)
            _buildCompleteSetButton(tvState),
        ],
      ),
    );
  }

  Widget _buildMainContent(TvModeState tvState) {
    if (tvState.isResting) {
      return Center(
        child: TvRestTimer(
          secondsRemaining: tvState.restSecondsRemaining,
          totalSeconds: tvState.restDurationSetting,
          onSkip: () => ref.read(tvModeProvider.notifier).skipRest(),
          onChangeDuration: (d) =>
              ref.read(tvModeProvider.notifier).setRestDuration(d),
        ),
      );
    }

    return ListView.builder(
      itemCount: tvState.exercises.length,
      itemBuilder: (context, index) {
        final exerciseState = tvState.exercises[index];
        final isCurrent = index == tvState.currentExerciseIndex;
        return TvExerciseCard(
          exerciseState: exerciseState,
          isCurrent: isCurrent,
          onTap: () =>
              ref.read(tvModeProvider.notifier).jumpToExercise(index),
        );
      },
    );
  }

  Widget _buildCompleteSetButton(TvModeState tvState) {
    final current = tvState.currentExercise;
    if (current == null) return const SizedBox.shrink();

    final nextSet = current.sets
        .where((s) => !s.completed)
        .firstOrNull;
    if (nextSet == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 72,
        child: ElevatedButton(
          onPressed: () =>
              ref.read(tvModeProvider.notifier).completeSet(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.primaryForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'COMPLETE SET ${nextSet.setNumber} OF ${current.sets.length}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
