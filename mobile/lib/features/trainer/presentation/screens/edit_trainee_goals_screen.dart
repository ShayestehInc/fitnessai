import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trainee_model.dart';
import '../providers/trainer_provider.dart';
import '../../../../shared/widgets/step_form_page.dart';

/// Full-page screen to edit trainee fitness goals.
class EditTraineeGoalsScreen extends ConsumerStatefulWidget {
  final TraineeDetailModel trainee;

  const EditTraineeGoalsScreen({super.key, required this.trainee});

  @override
  ConsumerState<EditTraineeGoalsScreen> createState() => _EditTraineeGoalsScreenState();
}

class _EditTraineeGoalsScreenState extends ConsumerState<EditTraineeGoalsScreen> {
  late String? _selectedGoal;
  late String? _selectedActivityLevel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.trainee.profile?.goal;
    _selectedActivityLevel = widget.trainee.profile?.activityLevel;
  }

  String _formatGoal(String goal) {
    switch (goal) {
      case 'build_muscle':
        return 'Build Muscle';
      case 'fat_loss':
        return 'Fat Loss';
      case 'recomp':
        return 'Body Recomposition';
      default:
        return goal;
    }
  }

  String _formatActivityLevel(String level) {
    switch (level) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly Active';
      case 'moderately_active':
        return 'Moderately Active';
      case 'very_active':
        return 'Very Active';
      case 'extremely_active':
        return 'Extremely Active';
      default:
        return level;
    }
  }

  String _getGoalDescription(String goal) {
    switch (goal) {
      case 'build_muscle':
        return 'Focus on gaining lean muscle mass with a calorie surplus';
      case 'fat_loss':
        return 'Prioritize losing body fat with a calorie deficit';
      case 'recomp':
        return 'Simultaneously build muscle and lose fat at maintenance calories';
      default:
        return '';
    }
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case 'build_muscle':
        return Icons.fitness_center;
      case 'fat_loss':
        return Icons.trending_down;
      case 'recomp':
        return Icons.sync;
      default:
        return Icons.flag;
    }
  }

  Future<void> _saveGoals() async {
    setState(() => _isLoading = true);

    final result = await ref.read(trainerRepositoryProvider).updateTraineeGoals(
      widget.trainee.id,
      goal: _selectedGoal,
      activityLevel: _selectedActivityLevel,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ref.invalidate(traineeDetailProvider(widget.trainee.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goals updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to update goals'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final traineeName = widget.trainee.firstName ?? widget.trainee.email.split('@').first;

    return StepFormPage(
      title: 'Edit Goals',
      completeButtonText: _isLoading ? 'Saving...' : 'Save Changes',
      onComplete: _isLoading ? null : _saveGoals,
      steps: [
        // Step 1: Primary Goal
        FormStep(
          title: 'Primary Goal',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What is $traineeName\'s primary goal?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will determine their nutrition targets and program recommendations.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              ...['build_muscle', 'fat_loss', 'recomp'].map((goal) {
                final isSelected = _selectedGoal == goal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedGoal = goal),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                  : theme.dividerColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getGoalIcon(goal),
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatGoal(goal),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getGoalDescription(goal),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // Step 2: Activity Level
        FormStep(
          title: 'Activity Level',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What is $traineeName\'s activity level?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This affects their daily calorie and macro targets.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              ...[
                'sedentary',
                'lightly_active',
                'moderately_active',
                'very_active',
                'extremely_active',
              ].map((level) {
                final isSelected = _selectedActivityLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedActivityLevel = level),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatActivityLevel(level),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : null,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
