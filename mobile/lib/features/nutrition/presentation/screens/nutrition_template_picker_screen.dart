import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Nutrition Template Picker — 4-card wizard entry point (Nutrition Spec §14).
class NutritionTemplatePickerScreen extends ConsumerWidget {
  const NutritionTemplatePickerScreen({super.key});

  static const _templates = [
    _TemplateOption(
      type: 'shredded',
      title: 'SHREDDED',
      subtitle: 'Fat loss carb cycling (structured)',
      badges: ['Added Fats', '1 High/week', 'LBM-based'],
      color: Color(0xFFEF4444),
      icon: Icons.local_fire_department,
    ),
    _TemplateOption(
      type: 'massive',
      title: 'MASSIVE',
      subtitle: 'Muscle gain carb cycling (structured)',
      badges: ['Added Fats', '2 High/week', 'LBM-based'],
      color: Color(0xFF3B82F6),
      icon: Icons.fitness_center,
    ),
    _TemplateOption(
      type: 'carb_cycling',
      title: 'Carb Cycling',
      subtitle: 'Flexible carb cycling (percent-based)',
      badges: ['Total Fat', 'Percent-based', 'Choose structure'],
      color: Color(0xFFF59E0B),
      icon: Icons.loop,
    ),
    _TemplateOption(
      type: 'custom',
      title: 'Create Your Own',
      subtitle: 'Build a custom template',
      badges: ['Advanced', 'Fully editable'],
      color: Color(0xFF8B5CF6),
      icon: Icons.build_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Choose Your Nutrition Template'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Pick a template that matches your goal. '
            'You can switch templates later — your history stays.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ..._templates.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TemplateCard(
                  option: t,
                  onTap: () => _onTemplateSelected(context, t.type),
                ),
              )),
          const SizedBox(height: 16),
          Text(
            'You can switch templates later. Your history stays.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onTemplateSelected(BuildContext context, String type) {
    // Route to the template-specific wizard
    context.push('/nutrition/template-wizard/$type');
  }
}

class _TemplateCard extends StatelessWidget {
  final _TemplateOption option;
  final VoidCallback onTap;

  const _TemplateCard({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: option.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: option.color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(option.icon, color: option.color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: option.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(option.subtitle, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: option.badges.map((b) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: option.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            b,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: option.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                  ),
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

class _TemplateOption {
  final String type;
  final String title;
  final String subtitle;
  final List<String> badges;
  final Color color;
  final IconData icon;

  const _TemplateOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.color,
    required this.icon,
  });
}
