import 'package:flutter/material.dart';

/// Card displaying a single observation from video analysis.
class ObservationCard extends StatelessWidget {
  final String observation;
  final int index;

  const ObservationCard({
    super.key,
    required this.observation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = _observationIcon(observation);
    final iconColor = _observationColor(observation);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              observation,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Infer an icon based on observation keywords.
  static IconData _observationIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('good') || lower.contains('great') || lower.contains('excellent')) {
      return Icons.thumb_up_outlined;
    }
    if (lower.contains('improve') || lower.contains('work on') || lower.contains('try')) {
      return Icons.lightbulb_outline;
    }
    if (lower.contains('warning') || lower.contains('risk') || lower.contains('caution')) {
      return Icons.warning_amber_rounded;
    }
    if (lower.contains('depth') || lower.contains('range') || lower.contains('motion')) {
      return Icons.straighten;
    }
    if (lower.contains('speed') || lower.contains('tempo') || lower.contains('pace')) {
      return Icons.speed;
    }
    if (lower.contains('back') || lower.contains('spine') || lower.contains('posture')) {
      return Icons.accessibility_new;
    }
    return Icons.info_outline;
  }

  /// Infer a color based on observation keywords.
  static Color _observationColor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('good') || lower.contains('great') || lower.contains('excellent')) {
      return const Color(0xFF22C55E);
    }
    if (lower.contains('warning') || lower.contains('risk') || lower.contains('caution')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF3B82F6);
  }
}
