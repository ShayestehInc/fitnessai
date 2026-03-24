import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Meal planning screen — supports copy-yesterday, plan-ahead,
/// and reusable meal templates (Nutrition Spec §12).
class MealPlanBuilderScreen extends ConsumerWidget {
  const MealPlanBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Meal Planner'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Quick actions
          _QuickActionCard(
            icon: Icons.content_copy_rounded,
            title: 'Copy Yesterday',
            subtitle: 'Use yesterday\'s meals as today\'s starting point',
            onTap: () {
              // TODO: Copy yesterday's MealLog entries
            },
          ),
          const SizedBox(height: 12),
          _QuickActionCard(
            icon: Icons.calendar_today_rounded,
            title: 'Plan Ahead',
            subtitle: 'Pre-plan meals for upcoming days',
            onTap: () {
              // TODO: Open day picker → pre-fill meals
            },
          ),
          const SizedBox(height: 12),
          _QuickActionCard(
            icon: Icons.bookmark_border_rounded,
            title: 'Saved Meals',
            subtitle: 'Use a saved meal template',
            onTap: () {
              // TODO: Show MealTemplate list
            },
          ),
          const SizedBox(height: 24),

          Text('Today\'s Meals', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          // Meal slots
          ...List.generate(6, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MealSlotCard(
                  mealNumber: i + 1,
                  mealName: _mealName(i),
                ),
              )),
        ],
      ),
    );
  }

  static String _mealName(int index) {
    const names = [
      'Breakfast',
      'Mid-Morning',
      'Lunch',
      'Afternoon',
      'Dinner',
      'Evening',
    ];
    return index < names.length ? names[index] : 'Meal ${index + 1}';
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
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

class _MealSlotCard extends StatelessWidget {
  final int mealNumber;
  final String mealName;

  const _MealSlotCard({
    required this.mealNumber,
    required this.mealName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              '$mealNumber',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(mealName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              // TODO: Add food to this meal slot
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Food'),
          ),
        ],
      ),
    );
  }
}
