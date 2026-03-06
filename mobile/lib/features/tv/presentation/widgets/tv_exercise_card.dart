import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/tv_mode_provider.dart';

/// Displays a single exercise in large, TV-readable format.
///
/// Shows exercise name, muscle group, sets with completion state,
/// and optional weight from last session.
class TvExerciseCard extends StatelessWidget {
  final TvExerciseState exerciseState;
  final bool isCurrent;
  final VoidCallback? onTap;

  const TvExerciseCard({
    super.key,
    required this.exerciseState,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = exerciseState.exercise;
    final allDone = exerciseState.allSetsCompleted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppTheme.primary.withValues(alpha: 0.15)
              : allDone
                  ? AppTheme.zinc800.withValues(alpha: 0.5)
                  : AppTheme.zinc900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? AppTheme.primary : AppTheme.zinc700,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Completion indicator
            _buildStatusIcon(allDone, isCurrent),
            const SizedBox(width: 20),
            // Exercise info
            Expanded(child: _buildExerciseInfo(exercise, allDone)),
            const SizedBox(width: 16),
            // Sets progress
            _buildSetsProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool allDone, bool isCurrent) {
    if (allDone) {
      return const Icon(
        Icons.check_circle,
        color: Color(0xFF22C55E),
        size: 36,
      );
    }
    if (isCurrent) {
      return const Icon(
        Icons.play_circle_filled,
        color: AppTheme.primary,
        size: 36,
      );
    }
    return const Icon(
      Icons.radio_button_unchecked,
      color: AppTheme.zinc500,
      size: 36,
    );
  }

  Widget _buildExerciseInfo(dynamic exercise, bool allDone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.name,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: allDone ? AppTheme.zinc500 : AppTheme.foreground,
            decoration: allDone ? TextDecoration.lineThrough : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              exercise.muscleGroup.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            if (exercise.lastWeight != null) ...[
              const SizedBox(width: 16),
              Text(
                'Last: ${exercise.lastWeight!.toStringAsFixed(1)} lbs',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.zinc400,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSetsProgress() {
    final completed = exerciseState.completedSetCount;
    final total = exerciseState.sets.length;
    final exercise = exerciseState.exercise;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$completed / $total',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppTheme.foreground,
          ),
        ),
        Text(
          '${exercise.targetReps} reps',
          style: const TextStyle(
            fontSize: 18,
            color: AppTheme.zinc400,
          ),
        ),
      ],
    );
  }
}
