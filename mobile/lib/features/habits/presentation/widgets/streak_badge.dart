import 'package:flutter/material.dart';

/// A compact badge that displays the current streak count with a fire icon.
///
/// Shows nothing when [streakCount] is zero to avoid visual clutter.
class StreakBadge extends StatelessWidget {
  final int streakCount;

  const StreakBadge({super.key, required this.streakCount});

  @override
  Widget build(BuildContext context) {
    if (streakCount <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 14,
            color: Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '$streakCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
