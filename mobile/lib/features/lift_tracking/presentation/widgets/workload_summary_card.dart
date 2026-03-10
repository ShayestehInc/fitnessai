import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/lift_models.dart';

/// Card showing total workload, set count, and rep count for a session.
class WorkloadSummaryCard extends StatelessWidget {
  final WorkloadSessionModel session;

  const WorkloadSummaryCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildMetricsRow(theme),
          if (session.topExercises.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTopExercises(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Workload',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
            Text(
              session.sessionDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            theme,
            label: 'Total',
            value: _formatWorkload(session.totalWorkload),
            icon: Icons.bar_chart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            theme,
            label: 'Sets',
            value: '${session.totalSets}',
            icon: Icons.repeat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            theme,
            label: 'Reps',
            value: '${session.totalReps}',
            icon: Icons.numbers,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.mutedForeground, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopExercises(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Exercises',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...session.topExercises.take(3).map(
              (exercise) => _buildExerciseRow(theme, exercise),
            ),
      ],
    );
  }

  Widget _buildExerciseRow(ThemeData theme, TopExerciseModel exercise) {
    final fraction = session.totalWorkload > 0
        ? exercise.workload / session.totalWorkload
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 4,
                    backgroundColor: AppTheme.zinc700,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatWorkload(exercise.workload),
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWorkload(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
