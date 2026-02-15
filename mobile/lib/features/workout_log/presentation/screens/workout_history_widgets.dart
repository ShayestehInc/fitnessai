import 'package:flutter/material.dart';
import '../../data/models/workout_history_model.dart';

/// Card widget for a single workout history item.
class WorkoutHistoryCard extends StatelessWidget {
  final WorkoutHistorySummary workout;
  final VoidCallback onTap;

  const WorkoutHistoryCard({
    super.key,
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '${workout.workoutName}, ${workout.formattedDate}, '
            '${workout.exerciseCount} exercises, '
            '${workout.totalSets} sets, '
            '${workout.durationDisplay}',
        child: Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    workout.formattedDate,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Workout name
                  Text(
                    workout.workoutName,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Stats row — Wrap prevents overflow on narrow screens
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      StatChip(
                        icon: Icons.fitness_center,
                        label: '${workout.exerciseCount} exercises',
                        theme: theme,
                      ),
                      StatChip(
                        icon: Icons.repeat,
                        label: '${workout.totalSets} sets',
                        theme: theme,
                      ),
                      StatChip(
                        icon: Icons.timer_outlined,
                        label: workout.durationDisplay,
                        theme: theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small icon + label chip used in history card stats row.
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
