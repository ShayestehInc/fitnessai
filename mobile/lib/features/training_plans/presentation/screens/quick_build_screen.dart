import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/builder_models.dart';
import '../providers/training_plan_provider.dart';
import '../widgets/expanded_brief_form.dart';
import '../widgets/why_panel.dart';

/// Quick Build: simple form -> generate -> review result with explanations.
class QuickBuildScreen extends ConsumerStatefulWidget {
  const QuickBuildScreen({super.key});

  @override
  ConsumerState<QuickBuildScreen> createState() => _QuickBuildScreenState();
}

class _QuickBuildScreenState extends ConsumerState<QuickBuildScreen> {
  // Core form state
  String _goal = 'build_muscle';
  int _daysPerWeek = 4;
  String _difficulty = 'intermediate';
  int _sessionLength = 60;
  Set<String> _equipment = {'barbell', 'dumbbell', 'cable'};
  String _style = '';
  Set<int> _selectedDays = {0, 1, 3, 4};
  // Expanded brief state
  String _secondaryGoal = '';
  List<String> _bodyPartEmphasis = [];
  int? _trainingAgeYears;
  String _skillLevel = '';
  Map<String, String> _recoveryProfile = {};
  Map<String, String> _painTolerances = {};
  List<String> _hatedLifts = [];
  String _complexityTolerance = '';

  bool _showResult = false;

  Future<void> _generate() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    final brief = BuilderBrief(
      traineeId: userId,
      goal: _goal,
      daysPerWeek: _daysPerWeek,
      difficulty: _difficulty,
      sessionLengthMinutes: _sessionLength,
      equipment: _equipment.toList(),
      style: _style,
      trainingDayIndices: _selectedDays.toList()..sort(),
      secondaryGoal: _secondaryGoal,
      bodyPartEmphasis: _bodyPartEmphasis,
      trainingAgeYears: _trainingAgeYears,
      skillLevel: _skillLevel,
      recoveryProfile: _recoveryProfile,
      painTolerances: _painTolerances,
      hatedLifts: _hatedLifts,
      complexityTolerance: _complexityTolerance,
    );

    setState(() => _showResult = true);
    ref.read(quickBuildProvider.notifier).build(brief);
  }

  @override
  Widget build(BuildContext context) {
    final buildState = ref.watch(quickBuildProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Build'),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: () {
            if (_showResult) {
              setState(() => _showResult = false);
              ref.read(quickBuildProvider.notifier).reset();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _showResult
          ? _buildResult(buildState)
          : _buildForm(buildState.isLoading),
    );
  }

  Widget _buildForm(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpandedBriefForm(
            goal: _goal,
            onGoalChanged: (v) => setState(() => _goal = v),
            daysPerWeek: _daysPerWeek,
            onDaysPerWeekChanged: (v) => setState(() => _daysPerWeek = v),
            selectedDays: _selectedDays,
            onSelectedDaysChanged: (v) => setState(() => _selectedDays = v),
            sessionLength: _sessionLength,
            onSessionLengthChanged: (v) => setState(() => _sessionLength = v),
            difficulty: _difficulty,
            onDifficultyChanged: (v) => setState(() => _difficulty = v),
            equipment: _equipment,
            onEquipmentChanged: (v) => setState(() => _equipment = v),
            style: _style,
            onStyleChanged: (v) => setState(() => _style = v),
            secondaryGoal: _secondaryGoal,
            onSecondaryGoalChanged: (v) => setState(() => _secondaryGoal = v),
            bodyPartEmphasis: _bodyPartEmphasis,
            onBodyPartEmphasisChanged: (v) => setState(() => _bodyPartEmphasis = v),
            trainingAgeYears: _trainingAgeYears,
            onTrainingAgeChanged: (v) => setState(() => _trainingAgeYears = v),
            skillLevel: _skillLevel,
            onSkillLevelChanged: (v) => setState(() => _skillLevel = v),
            recoveryProfile: _recoveryProfile,
            onRecoveryProfileChanged: (v) => setState(() => _recoveryProfile = v),
            painTolerances: _painTolerances,
            onPainTolerancesChanged: (v) => setState(() => _painTolerances = v),
            hatedLifts: _hatedLifts,
            onHatedLiftsChanged: (v) => setState(() => _hatedLifts = v),
            complexityTolerance: _complexityTolerance,
            onComplexityToleranceChanged: (v) => setState(() => _complexityTolerance = v),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : _generate,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate Program'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildResult(QuickBuildState state) {
    if (state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completed steps
              ...state.completedSteps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          step,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.zinc300,
                          ),
                        ),
                      ],
                    ),
                  )),
              // Current step
              if (state.progressStep != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state.progressStep!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.destructive, size: 48),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.mutedForeground),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() => _showResult = false);
                  ref.read(quickBuildProvider.notifier).reset();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final result = state.result;
    if (result == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.planName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.zinc300,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _StatChip(label: '${result.weeksCount} weeks'),
              const SizedBox(width: 8),
              _StatChip(label: '${result.sessionsCount} sessions'),
              const SizedBox(width: 8),
              _StatChip(label: '${result.slotsCount} exercises'),
            ],
          ),
          const SizedBox(height: 24),

          // Step explanations
          Text(
            'Why This Fits',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...result.stepExplanations.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WhyPanel(
                  stepName: e.stepName,
                  why: e.why,
                ),
              )),
          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                // Navigate to plan detail
                context.push('/plan-detail/${result.planId}');
              },
              child: const Text('View Plan Details'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                setState(() => _showResult = false);
                ref.read(quickBuildProvider.notifier).reset();
              },
              child: const Text('Build Another'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

}

class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.zinc300,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
