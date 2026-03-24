import 'package:flutter/material.dart';

/// Inline card shown after the final set of an exercise
/// displaying workload summary (v6.5 §10.5).
class ExerciseWorkloadCard extends StatelessWidget {
  final String exerciseName;
  final double totalWorkload;
  final String unit;
  final int setCount;
  final int repTotal;
  final double? deltaPercent;
  final String? factText;

  const ExerciseWorkloadCard({
    super.key,
    required this.exerciseName,
    required this.totalWorkload,
    required this.unit,
    required this.setCount,
    required this.repTotal,
    this.deltaPercent,
    this.factText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Exercise Complete',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetricChip(
                label: '${totalWorkload.toStringAsFixed(0)} $unit',
                theme: theme,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                label: '$setCount sets',
                theme: theme,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                label: '$repTotal reps',
                theme: theme,
              ),
              if (deltaPercent != null) ...[
                const SizedBox(width: 8),
                _DeltaChip(delta: deltaPercent!, theme: theme),
              ],
            ],
          ),
          if (factText != null && factText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              factText!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _MetricChip({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final double delta;
  final ThemeData theme;

  const _DeltaChip({required this.delta, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final color = isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$sign${delta.toStringAsFixed(1)}%',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
