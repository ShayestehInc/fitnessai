import 'package:flutter/material.dart';

/// Bottom sheet for the calm "feels off" lane (non-pain).
/// Distinct from pain triage — this is for wrong-muscle feel,
/// excessive difficulty, awkwardness, or wanting a swap.
class FeelsOffSheet extends StatelessWidget {
  final String exerciseName;
  final ValueChanged<String> onSelected;

  const FeelsOffSheet({
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
      builder: (_) => FeelsOffSheet(
        exerciseName: exerciseName,
        onSelected: (v) => Navigator.of(context).pop(v),
      ),
    );
  }

  static const _options = [
    _FeelsOffOption(
      type: 'wrong_muscles',
      icon: Icons.accessibility_new_rounded,
      label: 'Wrong muscles activating',
      description: 'I feel it in the wrong place. Suggest a same-pattern swap.',
    ),
    _FeelsOffOption(
      type: 'too_hard',
      icon: Icons.trending_up_rounded,
      label: 'Too heavy / too hard',
      description: 'The weight feels too ambitious today. Suggest a load reduction.',
    ),
    _FeelsOffOption(
      type: 'too_easy',
      icon: Icons.trending_down_rounded,
      label: 'Too easy',
      description: 'This is under-challenging. Note it for the progression engine.',
    ),
    _FeelsOffOption(
      type: 'awkward',
      icon: Icons.warning_amber_rounded,
      label: 'Exercise feels awkward',
      description: 'The movement doesn\'t feel right. Suggest a regression or swap.',
    ),
    _FeelsOffOption(
      type: 'swap',
      icon: Icons.swap_horiz_rounded,
      label: 'Just want to change exercise',
      description: 'Open the swap menu to pick something else.',
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
            'Something feels off?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'No pain — just not right. Pick what\'s happening:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ..._options.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onSelected(opt.type),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(opt.icon, size: 22, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(opt.description, style: theme.textTheme.bodySmall),
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

class _FeelsOffOption {
  final String type;
  final IconData icon;
  final String label;
  final String description;

  const _FeelsOffOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.description,
  });
}
