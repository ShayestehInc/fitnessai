import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/data/models/user_profile_model.dart';
import '../providers/settings_provider.dart';

class EditGoalsScreen extends ConsumerStatefulWidget {
  const EditGoalsScreen({super.key});

  @override
  ConsumerState<EditGoalsScreen> createState() => _EditGoalsScreenState();
}

class _EditGoalsScreenState extends ConsumerState<EditGoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsStateProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsStateProvider);
    final notifier = ref.read(settingsStateProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Fitness Goals',
          style: TextStyle(color: AppTheme.foreground),
        ),
        elevation: 0,
      ),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Level
                  Text(
                    'Activity Level',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How active are you on a typical week?',
                    style: TextStyle(color: AppTheme.mutedForeground),
                  ),
                  const SizedBox(height: 16),
                  ...ProfileEnums.activityLevels.map((level) {
                    final isSelected = state.profile?.activityLevel == level;
                    return GestureDetector(
                      onTap: () => notifier.updateActivityLevel(level),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.1)
                              : AppTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: level,
                              groupValue: state.profile?.activityLevel,
                              onChanged: (value) {
                                if (value != null) notifier.updateActivityLevel(value);
                              },
                              activeColor: AppTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ProfileEnums.activityLevelLabels[level] ?? level,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.foreground,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ProfileEnums.activityLevelDescriptions[level] ?? '',
                                    style: TextStyle(
                                      color: AppTheme.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Goal
                  Text(
                    'Your Goal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What do you want to achieve?',
                    style: TextStyle(color: AppTheme.mutedForeground),
                  ),
                  const SizedBox(height: 16),
                  ...ProfileEnums.goals.map((goal) {
                    final isSelected = state.profile?.goal == goal;
                    return GestureDetector(
                      onTap: () => notifier.updateGoal(goal),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.1)
                              : AppTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: goal,
                              groupValue: state.profile?.goal,
                              onChanged: (value) {
                                if (value != null) notifier.updateGoal(value);
                              },
                              activeColor: AppTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ProfileEnums.goalLabels[goal] ?? goal,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.foreground,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ProfileEnums.goalDescriptions[goal] ?? '',
                                    style: TextStyle(
                                      color: AppTheme.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              final success = await notifier.saveProfile();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Goals updated! Macros recalculated.'),
                                  ),
                                );
                                context.pop();
                              }
                            },
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
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
            ),
    );
  }
}
