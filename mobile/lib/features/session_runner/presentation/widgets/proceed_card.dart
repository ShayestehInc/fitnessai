import 'package:flutter/material.dart';

/// A tappable card representing a proceed decision after pain triage.
class ProceedCard extends StatelessWidget {
  final String decision;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const ProceedCard({
    super.key,
    required this.decision,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  /// All available proceed options per v6.5 §24.
  static const List<ProceedOption> allOptions = [
    ProceedOption(
      decision: 'continue_as_planned',
      title: 'Continue As Planned',
      subtitle: 'Pain is manageable. Keep going with the original plan.',
      icon: Icons.play_arrow_rounded,
    ),
    ProceedOption(
      decision: 'continue_with_adjustment',
      title: 'Continue With Changes',
      subtitle: 'Apply the adjustments above and keep training.',
      icon: Icons.tune_rounded,
    ),
    ProceedOption(
      decision: 'swap_exercise',
      title: 'Swap Exercise',
      subtitle: 'Replace with a same-muscle or same-pattern alternative.',
      icon: Icons.swap_horiz_rounded,
    ),
    ProceedOption(
      decision: 'skip_slot',
      title: 'Skip This Exercise',
      subtitle: 'Skip remaining sets and move to the next exercise.',
      icon: Icons.skip_next_rounded,
    ),
    ProceedOption(
      decision: 'stop_session',
      title: 'End Session',
      subtitle: 'Stop the workout. Your trainer will be notified.',
      icon: Icons.stop_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDestructive = decision == 'stop_session';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFEF4444).withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: isDestructive
                  ? const Color(0xFFEF4444)
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? const Color(0xFFEF4444) : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.dividerColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for a proceed option.
class ProceedOption {
  final String decision;
  final String title;
  final String subtitle;
  final IconData icon;

  const ProceedOption({
    required this.decision,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
