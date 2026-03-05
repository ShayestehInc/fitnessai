import 'package:flutter/material.dart';

/// Displays a group of exercises (superset, circuit, or drop set).
/// Exercises with the same group_id are visually connected.
class ExerciseGroupCard extends StatelessWidget {
  final String groupId;
  final String groupType;
  final List<Map<String, dynamic>> exercises;
  final void Function(int exerciseIndex, int setIndex)? onSetCompleted;

  const ExerciseGroupCard({
    super.key,
    required this.groupId,
    required this.groupType,
    required this.exercises,
    this.onSetCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupColor = _groupTypeColor(theme);
    final groupLabel = _groupTypeLabel();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: groupColor.withValues(alpha: 0.15),
            child: Row(
              children: [
                Icon(_groupTypeIcon(), size: 18, color: groupColor),
                const SizedBox(width: 8),
                Text(
                  groupLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: groupColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${exercises.length} exercises',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: groupColor,
                  ),
                ),
              ],
            ),
          ),

          // Exercise list with connecting lines
          ...List.generate(exercises.length, (index) {
            final exercise = exercises[index];
            final isLast = index == exercises.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Connecting line
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isLast ? Colors.transparent : groupColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Exercise content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise['exercise_name'] as String? ?? 'Unknown Exercise',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildSetSummary(exercise),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (exercise['rest_seconds'] != null &&
                              exercise['rest_seconds'] != 0 &&
                              !isLast)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Rest: ${exercise['rest_seconds']}s',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: groupColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _groupTypeLabel() {
    switch (groupType) {
      case 'superset':
        return 'Superset';
      case 'circuit':
        return 'Circuit';
      case 'drop_set':
        return 'Drop Set';
      default:
        return 'Group';
    }
  }

  IconData _groupTypeIcon() {
    switch (groupType) {
      case 'superset':
        return Icons.swap_vert;
      case 'circuit':
        return Icons.loop;
      case 'drop_set':
        return Icons.trending_down;
      default:
        return Icons.group_work;
    }
  }

  Color _groupTypeColor(ThemeData theme) {
    switch (groupType) {
      case 'superset':
        return Colors.deepPurple;
      case 'circuit':
        return Colors.teal;
      case 'drop_set':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _buildSetSummary(Map<String, dynamic> exercise) {
    final sets = exercise['sets'];
    final reps = exercise['reps'];
    final weight = exercise['weight'];
    final unit = exercise['unit'] ?? 'lbs';

    final parts = <String>[];
    if (sets != null) parts.add('$sets sets');
    if (reps != null) parts.add('$reps reps');
    if (weight != null) parts.add('$weight $unit');
    return parts.join(' × ');
  }
}
