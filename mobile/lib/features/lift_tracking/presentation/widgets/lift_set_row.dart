import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/lift_models.dart';

/// Displays a single lift set log row with date, load, reps, and RPE.
class LiftSetRow extends StatelessWidget {
  final LiftSetLogModel setLog;

  const LiftSetRow({super.key, required this.setLog});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildSetBadge(theme),
          const SizedBox(width: 12),
          Expanded(child: _buildDetails(theme)),
          _buildMetrics(theme),
        ],
      ),
    );
  }

  Widget _buildSetBadge(ThemeData theme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '${setLog.setNumber}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          setLog.loadDisplay,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          setLog.sessionDate,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMetricChip(
          theme,
          label: 'Reps',
          value: '${setLog.completedReps}',
        ),
        if (setLog.rpe != null) ...[
          const SizedBox(width: 8),
          _buildMetricChip(
            theme,
            label: 'RPE',
            value: setLog.rpe!.toStringAsFixed(
              setLog.rpe!.truncateToDouble() == setLog.rpe! ? 0 : 1,
            ),
            highlight: setLog.rpe! >= 9,
          ),
        ],
      ],
    );
  }

  Widget _buildMetricChip(
    ThemeData theme, {
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.destructive.withOpacity(0.1)
            : AppTheme.zinc800,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: highlight ? AppTheme.destructive : AppTheme.foreground,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedForeground,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
