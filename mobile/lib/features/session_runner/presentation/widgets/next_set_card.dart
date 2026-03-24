import 'package:flutter/material.dart';

/// Preview card showing what's coming in the next set (v6.5 §10.2).
class NextSetCard extends StatelessWidget {
  final int setNumber;
  final int totalSets;
  final int prescribedRepsMin;
  final int prescribedRepsMax;
  final double? suggestedLoad;
  final String loadUnit;
  final String? tempo;
  final String? cue;

  const NextSetCard({
    super.key,
    required this.setNumber,
    required this.totalSets,
    required this.prescribedRepsMin,
    required this.prescribedRepsMax,
    this.suggestedLoad,
    this.loadUnit = 'lb',
    this.tempo,
    this.cue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final repsText = prescribedRepsMin == prescribedRepsMax
        ? '$prescribedRepsMin reps'
        : '$prescribedRepsMin-$prescribedRepsMax reps';

    final loadText = suggestedLoad != null
        ? '${suggestedLoad!.toStringAsFixed(0)} $loadUnit'
        : 'TBD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
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
                Icons.upcoming_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Next: Set $setNumber of $totalSets',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(label: repsText, theme: theme),
              const SizedBox(width: 8),
              _InfoChip(label: loadText, theme: theme),
              if (tempo != null) ...[
                const SizedBox(width: 8),
                _InfoChip(label: tempo!, theme: theme),
              ],
            ],
          ),
          if (cue != null && cue!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cue!,
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

class _InfoChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _InfoChip({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
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
