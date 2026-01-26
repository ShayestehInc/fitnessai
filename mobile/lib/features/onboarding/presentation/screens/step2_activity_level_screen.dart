import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_profile_model.dart';
import '../providers/onboarding_provider.dart';

class Step2ActivityLevelScreen extends ConsumerWidget {
  const Step2ActivityLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingStateProvider);
    final notifier = ref.read(onboardingStateProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => notifier.goBack(),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: AppTheme.mutedForeground),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(color: AppTheme.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Activity Level',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'How active are you on a typical week?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
          ),
          const SizedBox(height: 32),

          // Activity level options
          ...ProfileEnums.activityLevels.map((level) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityLevelCard(
                level: level,
                label: ProfileEnums.activityLevelLabels[level] ?? level,
                description: ProfileEnums.activityLevelDescriptions[level] ?? '',
                isSelected: state.activityLevel == level,
                onTap: () => notifier.setActivityLevel(level),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.canProceedStep2 && !state.isLoading
                  ? () => notifier.saveStep2()
                  : null,
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ),

          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(color: AppTheme.destructive),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityLevelCard extends StatelessWidget {
  final String level;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityLevelCard({
    required this.level,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (level) {
      case 'sedentary':
        return Icons.weekend;
      case 'lightly_active':
        return Icons.directions_walk;
      case 'moderately_active':
        return Icons.directions_run;
      case 'very_active':
        return Icons.fitness_center;
      case 'extremely_active':
        return Icons.sports_martial_arts;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.zinc800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _icon,
                color: isSelected ? AppTheme.primary : AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
