import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import 'step1_about_you_screen.dart';
import 'step2_activity_level_screen.dart';
import 'step3_goal_screen.dart';
import 'step4_diet_setup_screen.dart';

class OnboardingWizardScreen extends ConsumerWidget {
  const OnboardingWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingStateProvider);

    // Navigate to home when completed
    if (state.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Update auth state to reflect onboarding completion
        ref.read(authStateProvider.notifier).markOnboardingCompleted();
        context.go('/home');
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(state.currentStep),

            // Step content
            Expanded(
              child: _buildStepContent(state.currentStep),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: List.generate(4, (index) {
          final stepNumber = index + 1;
          final isCompleted = stepNumber < currentStep;
          final isCurrent = stepNumber == currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppTheme.primary
                          : AppTheme.zinc700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 1:
        return const Step1AboutYouScreen();
      case 2:
        return const Step2ActivityLevelScreen();
      case 3:
        return const Step3GoalScreen();
      case 4:
        return const Step4DietSetupScreen();
      default:
        return const Step1AboutYouScreen();
    }
  }
}
