import 'package:flutter/material.dart';

import '../../data/models/session_models.dart';

/// Displays the current exercise name, slot role badge, set count,
/// and prescribed reps/load for quick reference.
class ExerciseHeaderWidget extends StatelessWidget {
  final SessionSlotModel slot;
  final SessionSetModel? currentSet;

  const ExerciseHeaderWidget({
    super.key,
    required this.slot,
    this.currentSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  slot.exerciseName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SlotRoleBadge(slotRole: slot.slotRole),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _setCountText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (currentSet != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${currentSet!.prescribedRepsDisplay} reps',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.scale,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  currentSet!.prescribedLoadDisplay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String get _setCountText {
    final completed = slot.completedSets + slot.skippedSets;
    return 'Set ${completed + 1} of ${slot.totalSets}';
  }
}

class _SlotRoleBadge extends StatelessWidget {
  final String slotRole;

  const _SlotRoleBadge({required this.slotRole});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color badgeColor;
    switch (slotRole) {
      case 'compound':
        badgeColor = colorScheme.primary;
      case 'accessory':
        badgeColor = colorScheme.tertiary;
      case 'mobility':
        badgeColor = colorScheme.secondary;
      default:
        badgeColor = colorScheme.outline;
    }

    final displayName = switch (slotRole) {
      'compound' => 'Compound',
      'accessory' => 'Accessory',
      'mobility' => 'Mobility',
      _ => slotRole,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
