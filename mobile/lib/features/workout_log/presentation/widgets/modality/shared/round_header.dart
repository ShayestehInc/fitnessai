import 'package:flutter/material.dart';

/// "Round 1 of 4" header for supersets, giant sets, and circuits.
class RoundHeader extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final bool isActive;
  final String? label; // Optional override like "Superset A" or "Circuit"

  const RoundHeader({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    this.isActive = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.loop,
            size: 14,
            color: isActive
                ? theme.colorScheme.primary
                : theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 6),
          Text(
            label ?? 'Round $currentRound of $totalRounds',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
          ),
          const Spacer(),
          // Progress dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalRounds, (i) {
              final completed = i < currentRound;
              final current = i == currentRound - 1;
              return Container(
                width: current ? 10 : 6,
                height: 6,
                margin: const EdgeInsets.only(left: 3),
                decoration: BoxDecoration(
                  color: completed
                      ? theme.colorScheme.primary
                      : current
                          ? theme.colorScheme.primary.withValues(alpha: 0.5)
                          : theme.dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
