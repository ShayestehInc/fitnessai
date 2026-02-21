import 'package:flutter/material.dart';

class SplitTypeOption {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const SplitTypeOption({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const splitTypeOptions = [
  SplitTypeOption(
    key: 'ppl',
    label: 'Push / Pull / Legs',
    description: 'Push, Pull, Legs — classic 3-day rotation',
    icon: Icons.layers_outlined,
  ),
  SplitTypeOption(
    key: 'upper_lower',
    label: 'Upper / Lower',
    description: 'Alternate upper and lower body days',
    icon: Icons.swap_vert_outlined,
  ),
  SplitTypeOption(
    key: 'full_body',
    label: 'Full Body',
    description: 'Hit every muscle group each session',
    icon: Icons.fitness_center_outlined,
  ),
  SplitTypeOption(
    key: 'bro_split',
    label: 'Bro Split',
    description: 'One muscle group per day',
    icon: Icons.grid_view_outlined,
  ),
  SplitTypeOption(
    key: 'custom',
    label: 'Custom Split',
    description: 'Choose your own muscle groups per day',
    icon: Icons.tune_outlined,
  ),
];

class SplitTypeCard extends StatelessWidget {
  final SplitTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  const SplitTypeCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surface,
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                option.icon,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected ? colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
