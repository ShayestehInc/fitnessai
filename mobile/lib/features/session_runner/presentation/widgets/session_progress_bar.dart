import 'package:flutter/material.dart';

import '../../data/models/session_models.dart';

/// A segmented progress bar showing each set's status with color coding.
/// Green = completed, gray = pending, orange = skipped, with the current
/// set highlighted with a border.
class SessionProgressBar extends StatelessWidget {
  final ActiveSessionModel session;

  const SessionProgressBar({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final allSets = <_SetStatus>[];
    for (final slot in session.slots) {
      for (final set in slot.sets) {
        allSets.add(_SetStatus(
          status: set.status,
          isCurrent: slot.isCurrent && set.isPending && _isFirstPending(slot, set),
        ));
      }
    }

    if (allSets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${session.completedSets} of ${session.totalSets} sets',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${session.progressPct.toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 8,
          child: Row(
            children: allSets.asMap().entries.map((entry) {
              final index = entry.key;
              final setStatus = entry.value;

              Color color;
              switch (setStatus.status) {
                case 'completed':
                  color = Colors.green;
                case 'skipped':
                  color = Colors.orange;
                default:
                  color = colorScheme.surfaceContainerHighest;
              }

              final isFirst = index == 0;
              final isLast = index == allSets.length - 1;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: isFirst ? 0 : 1,
                    right: isLast ? 0 : 1,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.horizontal(
                      left: isFirst
                          ? const Radius.circular(4)
                          : Radius.zero,
                      right: isLast
                          ? const Radius.circular(4)
                          : Radius.zero,
                    ),
                    border: setStatus.isCurrent
                        ? Border.all(
                            color: colorScheme.primary,
                            width: 1.5,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const _LegendDot(color: Colors.green, label: 'Done'),
            const SizedBox(width: 12),
            _LegendDot(
              color: colorScheme.surfaceContainerHighest,
              label: 'Pending',
            ),
            const SizedBox(width: 12),
            const _LegendDot(color: Colors.orange, label: 'Skipped'),
          ],
        ),
      ],
    );
  }

  bool _isFirstPending(SessionSlotModel slot, SessionSetModel set) {
    for (final s in slot.sets) {
      if (s.isPending) return s.setLogId == set.setLogId;
    }
    return false;
  }
}

class _SetStatus {
  final String status;
  final bool isCurrent;

  const _SetStatus({required this.status, required this.isCurrent});
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
