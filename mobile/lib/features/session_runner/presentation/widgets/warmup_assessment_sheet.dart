import 'package:flutter/material.dart';

/// Bottom sheet shown before the first set of an exercise to assess
/// warmup need (v6.5 §10.3).
class WarmupAssessmentSheet extends StatelessWidget {
  final String exerciseName;
  final ValueChanged<String> onSelected;

  const WarmupAssessmentSheet({
    super.key,
    required this.exerciseName,
    required this.onSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    required String exerciseName,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WarmupAssessmentSheet(
        exerciseName: exerciseName,
        onSelected: (v) => Navigator.of(context).pop(v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Before you start: $exerciseName',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'How does your body feel for this movement?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _AssessmentOption(
            icon: Icons.healing_rounded,
            label: 'Something hurts here',
            subtitle: 'Get pump/prehab drills',
            color: const Color(0xFFEF4444),
            onTap: () => onSelected('hurts'),
          ),
          const SizedBox(height: 8),
          _AssessmentOption(
            icon: Icons.accessibility_new_rounded,
            label: 'Feeling stiff',
            subtitle: 'Get mobility drills',
            color: const Color(0xFFF59E0B),
            onTap: () => onSelected('stiff'),
          ),
          const SizedBox(height: 8),
          _AssessmentOption(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Want technique tips',
            subtitle: 'Get cues and strategy',
            color: const Color(0xFF3B82F6),
            onTap: () => onSelected('technique'),
          ),
          const SizedBox(height: 8),
          _AssessmentOption(
            icon: Icons.check_circle_outline_rounded,
            label: "I'm ready",
            subtitle: 'Go straight to working sets',
            color: const Color(0xFF22C55E),
            onTap: () => onSelected('ready'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AssessmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AssessmentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.dividerColor),
          ],
        ),
      ),
    );
  }
}
