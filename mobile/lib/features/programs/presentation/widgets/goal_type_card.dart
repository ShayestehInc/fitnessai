import 'package:flutter/material.dart';

class GoalTypeOption {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const GoalTypeOption({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const goalTypeOptions = [
  GoalTypeOption(
    key: 'build_muscle',
    label: 'Build Muscle',
    description: 'Hypertrophy-focused training for size gains',
    icon: Icons.fitness_center_outlined,
  ),
  GoalTypeOption(
    key: 'fat_loss',
    label: 'Fat Loss',
    description: 'High-intensity training for calorie burn',
    icon: Icons.local_fire_department_outlined,
  ),
  GoalTypeOption(
    key: 'strength',
    label: 'Strength',
    description: 'Heavy compound lifts for raw strength',
    icon: Icons.bolt_outlined,
  ),
  GoalTypeOption(
    key: 'endurance',
    label: 'Endurance',
    description: 'Higher reps and shorter rest periods',
    icon: Icons.timer_outlined,
  ),
  GoalTypeOption(
    key: 'recomp',
    label: 'Recomp',
    description: 'Build muscle while losing fat simultaneously',
    icon: Icons.swap_horiz_outlined,
  ),
  GoalTypeOption(
    key: 'general_fitness',
    label: 'General Fitness',
    description: 'Well-rounded program for overall health',
    icon: Icons.favorite_outlined,
  ),
];

class GoalTypeCard extends StatelessWidget {
  final GoalTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  const GoalTypeCard({
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
