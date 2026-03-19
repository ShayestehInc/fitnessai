import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';

/// Entry screen for the dual-mode program builder.
/// Users choose between Quick Build and Advanced Builder.
class BuilderModeScreen extends StatelessWidget {
  const BuilderModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build a Program'),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'How do you want to build?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your level of control over the plan design.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
              ),
              const SizedBox(height: 32),
              _BuilderModeCard(
                title: 'Quick Build',
                subtitle: 'Answer a few questions, AI does the rest',
                description:
                    'Tell us your goal, schedule, equipment, and preferences. '
                    'We\'ll build a complete plan and explain why it fits.',
                icon: Icons.flash_on_rounded,
                iconColor: const Color(0xFFFBBF24),
                features: const [
                  'Ready in seconds',
                  'Smart defaults for everything',
                  'Full explanation of choices',
                  'Tweak big levers after',
                ],
                onTap: () => context.push('/quick-build'),
              ),
              const SizedBox(height: 16),
              _BuilderModeCard(
                title: 'Advanced Builder',
                subtitle: 'Guide every decision step by step',
                description:
                    'Walk through each layer of program design. See why each '
                    'choice was made, pick from alternatives, and override anything.',
                icon: Icons.tune_rounded,
                iconColor: AppTheme.primary,
                features: const [
                  '9 decision steps',
                  'Why panel at every layer',
                  'Override any choice',
                  'Full diff and history',
                ],
                onTap: () => context.push('/advanced-builder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuilderModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color iconColor;
  final List<String> features;
  final VoidCallback onTap;

  const _BuilderModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedForeground,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.mutedForeground,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.zinc400,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: features
                  .map((f) => _FeatureChip(label: f))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.zinc400,
            ),
      ),
    );
  }
}
