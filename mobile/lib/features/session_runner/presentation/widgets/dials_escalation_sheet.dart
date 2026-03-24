import 'package:flutter/material.dart';

/// Bottom sheet showing the default dials escalation ladder
/// when failure flags fire mid-session (v6.5 §10.4).
///
/// Ladder: cue → tempo/pause → reduce load → reduce ROM → stance change → swap
class DialsEscalationSheet extends StatelessWidget {
  final String exerciseName;
  final ValueChanged<String> onSelected;

  const DialsEscalationSheet({
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DialsEscalationSheet(
        exerciseName: exerciseName,
        onSelected: (v) => Navigator.of(context).pop(v),
      ),
    );
  }

  static const _steps = [
    _EscalationStep(
      type: 'cue',
      icon: Icons.record_voice_over_rounded,
      title: 'Focus on Cue',
      description: 'Adjust your focus: brace harder, drive through heels, control the eccentric.',
    ),
    _EscalationStep(
      type: 'tempo',
      icon: Icons.slow_motion_video_rounded,
      title: 'Change Tempo',
      description: 'Slow down the movement or add a pause to reduce peak forces.',
    ),
    _EscalationStep(
      type: 'load',
      icon: Icons.fitness_center_rounded,
      title: 'Reduce Load',
      description: 'Drop the weight by 10-20% and focus on quality reps.',
    ),
    _EscalationStep(
      type: 'rom',
      icon: Icons.height_rounded,
      title: 'Shorten Range of Motion',
      description: 'Work in the pain-free portion of the range.',
    ),
    _EscalationStep(
      type: 'stance',
      icon: Icons.swap_vert_rounded,
      title: 'Change Stance / Support',
      description: 'Adjust foot position, grip width, or add support gear.',
    ),
    _EscalationStep(
      type: 'swap',
      icon: Icons.swap_horiz_rounded,
      title: 'Swap Exercise',
      description: 'Switch to a same-muscle or same-pattern alternative.',
    ),
  ];

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
            'Having trouble with $exerciseName?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Try these adjustments in order:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ..._steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onSelected(step.type),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(step.icon, size: 24, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(step.description, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EscalationStep {
  final String type;
  final IconData icon;
  final String title;
  final String description;

  const _EscalationStep({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
  });
}
