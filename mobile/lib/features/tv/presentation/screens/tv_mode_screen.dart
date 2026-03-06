import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../workout_log/presentation/providers/workout_provider.dart';
import '../providers/tv_mode_provider.dart';
import '../widgets/tv_empty_states.dart';
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadWorkout();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _loadWorkout() {
    final workoutState = ref.read(workoutStateProvider);

    if (workoutState.isLoading || workoutState.programs.isEmpty) {
      Future.microtask(() async {
        try {
          await ref.read(workoutStateProvider.notifier).loadInitialData();
        } on Exception {
          if (mounted) {
            ref.read(tvModeProvider.notifier).setError('no_workout');
          }
          return;
        }
        if (mounted) _initFromWorkoutState();
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
    if (workoutState.activeProgram == null) return 'no_program';
    final week = workoutState.selectedWeek;
    if (week == null) return 'no_workout';
    final todayWorkout = week.workouts.where((w) => w.isToday).firstOrNull;
    if (todayWorkout != null && todayWorkout.isRestDay) return 'rest_day';
    return 'no_workout';
  }

  void _handleExit() => context.pop();

  @override
  Widget build(BuildContext context) {
    final tvState = ref.watch(tvModeProvider);
    final workoutState = ref.watch(workoutStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      body: SafeArea(
        child: tvState.isLoading
            ? const TvLoadingView()
            : tvState.error != null
                ? TvEmptyView(
                    reason: tvState.error!,
                    workoutState: workoutState,
                    onExit: _handleExit,
                  )
                : tvState.workoutComplete
                    ? TvCompleteView(
                        tvState: tvState,
                        onExit: _handleExit,
                      )
                    : _TvWorkoutView(
                        tvState: tvState,
                        workoutState: workoutState,
                        onExit: _handleExit,
                      ),
      ),
    );
  }
}

/// Active workout display with exercises, rest timer, and complete button.
class _TvWorkoutView extends ConsumerWidget {
  final TvModeState tvState;
  final WorkoutState workoutState;
  final VoidCallback onExit;

  const _TvWorkoutView({
    required this.tvState,
    required this.workoutState,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TvWorkoutHeader(
            programName: workoutState.activeProgram?.name ?? 'Workout',
            dayName: workoutState.todaysWorkout?.name ?? 'Today',
            elapsed: tvState.elapsed,
            onExit: onExit,
          ),
          const SizedBox(height: 16),
          TvProgressBar(
            fraction: tvState.progressFraction,
            completedExercises: tvState.completedExercises,
            totalExercises: tvState.totalExercises,
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildMainContent(ref)),
          if (!tvState.isResting && !tvState.workoutComplete)
            _buildCompleteSetButton(ref),
        ],
      ),
    );
  }

  Widget _buildMainContent(WidgetRef ref) {
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
        return TvExerciseCard(
          exerciseState: tvState.exercises[index],
          isCurrent: index == tvState.currentExerciseIndex,
          onTap: () =>
              ref.read(tvModeProvider.notifier).jumpToExercise(index),
        );
      },
    );
  }

  Widget _buildCompleteSetButton(WidgetRef ref) {
    final current = tvState.currentExercise;
    if (current == null) return const SizedBox.shrink();

    final nextSet = current.sets.where((s) => !s.completed).firstOrNull;
    if (nextSet == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 72,
        child: ElevatedButton(
          onPressed: () => ref.read(tvModeProvider.notifier).completeSet(),
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
