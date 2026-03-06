import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../workout_log/presentation/providers/workout_provider.dart';
import '../providers/tv_mode_provider.dart';

/// Loading state for TV mode.
class TvLoadingView extends StatelessWidget {
  const TvLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(fontSize: 24, color: AppTheme.zinc400),
          ),
        ],
      ),
    );
  }
}

/// Empty/error state for TV mode (no program, rest day, no workout).
class TvEmptyView extends StatelessWidget {
  final String reason;
  final WorkoutState workoutState;
  final VoidCallback onExit;

  const TvEmptyView({
    super.key,
    required this.reason,
    required this.workoutState,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
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
        subtitle = _buildNextWorkoutHint();
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
          TvExitButton(onExit: onExit),
        ],
      ),
    );
  }

  String _buildNextWorkoutHint() {
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
}

/// Workout complete celebration view for TV mode.
class TvCompleteView extends StatelessWidget {
  final TvModeState tvState;
  final VoidCallback onExit;

  const TvCompleteView({
    super.key,
    required this.tvState,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
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
            '${tvState.totalExercises} exercises \u2022 '
            '${tvState.totalSets} sets \u2022 '
            '${minutes}m ${seconds}s',
            style: const TextStyle(fontSize: 24, color: AppTheme.zinc300),
          ),
          const SizedBox(height: 48),
          TvExitButton(onExit: onExit),
        ],
      ),
    );
  }
}

/// Reusable exit button for TV mode.
class TvExitButton extends StatelessWidget {
  final VoidCallback onExit;

  const TvExitButton({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onExit,
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
}
