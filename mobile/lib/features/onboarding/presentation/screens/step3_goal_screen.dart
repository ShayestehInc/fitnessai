import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_profile_model.dart';
import '../providers/onboarding_provider.dart';

class Step3GoalScreen extends ConsumerWidget {
  const Step3GoalScreen({super.key});

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
            'Your Goal',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'What would you like to achieve?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
          ),
          const SizedBox(height: 32),

          // Goal options
          ...ProfileEnums.goals.map((goal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GoalCard(
                goal: goal,
                label: ProfileEnums.goalLabels[goal] ?? goal,
                description: ProfileEnums.goalDescriptions[goal] ?? '',
                isSelected: state.goal == goal,
                onTap: () => notifier.setGoal(goal),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.canProceedStep3 && !state.isLoading
                  ? () => notifier.saveStep3()
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

class _GoalCard extends StatelessWidget {
  final String goal;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (goal) {
      case 'build_muscle':
        return Icons.fitness_center;
      case 'fat_loss':
        return Icons.local_fire_department;
      case 'recomp':
        return Icons.swap_vert;
      default:
        return Icons.flag;
    }
  }

  Color get _iconColor {
    switch (goal) {
      case 'build_muscle':
        return Colors.blue;
      case 'fat_loss':
        return Colors.orange;
      case 'recomp':
        return Colors.purple;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon,
                color: _iconColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.foreground,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primary, size: 28),
          ],
        ),
      ),
    );
  }
}
