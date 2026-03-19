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

/// Advanced Builder: step-by-step wizard where the coach controls every layer.
class AdvancedBuilderScreen extends ConsumerStatefulWidget {
  const AdvancedBuilderScreen({super.key});

  @override
  ConsumerState<AdvancedBuilderScreen> createState() =>
      _AdvancedBuilderScreenState();
}

class _AdvancedBuilderScreenState
    extends ConsumerState<AdvancedBuilderScreen> {
  // Brief form state (shown as step 0 before calling the API)
  bool _briefSubmitted = false;
  String _goal = 'build_muscle';
  int _daysPerWeek = 4;
  String _difficulty = 'intermediate';
  int _sessionLength = 60;
  Set<String> _equipment = {'barbell', 'dumbbell', 'cable'};
  Set<int> _selectedDays = {0, 1, 3, 4};
  String _style = '';
  // Expanded brief state
  String _secondaryGoal = '';
  List<String> _bodyPartEmphasis = [];
  int? _trainingAgeYears;
  String _skillLevel = '';
  Map<String, String> _recoveryProfile = {};
  Map<String, String> _painTolerances = {};
  List<String> _hatedLifts = [];
  String _complexityTolerance = '';

  static const _stepLabels = [
    'Brief',
    'Length',
    'Split',
    'Skeleton',
    'Roles',
    'Structures',
    'Exercises',
    'Swaps',
    'Progression',
    'Publish',
  ];

  Future<void> _submitBrief() async {
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

    await ref.read(advancedBuilderProvider.notifier).start(brief);
    setState(() => _briefSubmitted = true);
  }

  Future<void> _acceptStep() async {
    await ref.read(advancedBuilderProvider.notifier).advance();
  }

  Future<void> _overrideStep(Map<String, dynamic> override) async {
    await ref
        .read(advancedBuilderProvider.notifier)
        .advance(override: override);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(advancedBuilderProvider);
    final currentStepNum = _briefSubmitted
        ? (state.currentStepResult?.currentStepNumber ?? 0)
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentStepNum < _stepLabels.length
              ? _stepLabels[currentStepNum]
              : 'Builder',
        ),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: () {
            if (!_briefSubmitted) {
              context.pop();
            } else {
              // Could implement step-back in the future
              context.pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Step progress bar
          _buildProgressBar(currentStepNum),
          Expanded(
            child: _briefSubmitted
                ? _buildStepContent(state)
                : _buildBriefForm(state.isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppTheme.card,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Step ${currentStep + 1} of ${_stepLabels.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const Spacer(),
              Text(
                currentStep < _stepLabels.length
                    ? _stepLabels[currentStep]
                    : 'Complete',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / _stepLabels.length,
              backgroundColor: AppTheme.zinc700,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefForm(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Detailed Brief',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us about the trainee\'s goals and constraints.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
          ),
          const SizedBox(height: 24),
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
              onPressed: isLoading ? null : _submitBrief,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start Building'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepContent(AdvancedBuilderState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppTheme.destructive, size: 48),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.mutedForeground),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _acceptStep,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final step = state.currentStepResult;
    if (step == null) return const SizedBox.shrink();

    // If the builder is complete, show final result
    if (step.currentStep == 'complete') {
      return _buildCompleteView(step);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recommendation card
          _buildRecommendationCard(step),
          const SizedBox(height: 16),

          // Why panel
          WhyPanel(
            stepName: step.currentStep,
            why: step.why,
            initiallyExpanded: true,
          ),
          const SizedBox(height: 16),

          // Alternatives
          if (step.alternatives.isNotEmpty) ...[
            AlternativesPanel(
              alternatives: step.alternatives,
              onSelect: (alt) => _overrideStep(alt),
            ),
            const SizedBox(height: 16),
          ],

          // Preview section
          if (step.preview.isNotEmpty) ...[
            _buildPreview(step.preview),
            const SizedBox(height: 16),
          ],

          // Action buttons
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: state.isLoading ? null : _acceptStep,
              child: Text(
                step.currentStep == 'publish'
                    ? 'Publish Plan'
                    : 'Accept & Continue',
              ),
            ),
          ),
          if (step.currentStep == 'publish') ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () => _overrideStep({'action': 'save_draft'}),
                child: const Text('Save as Draft'),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuilderStepResult step) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Recommendation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRecommendationBody(step),
        ],
      ),
    );
  }

  Widget _buildRecommendationBody(BuilderStepResult step) {
    final rec = step.recommendation;
    switch (step.currentStep) {
      case 'length':
        return Text(
          '${rec['weeks']} weeks',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.foreground,
                fontWeight: FontWeight.w700,
              ),
        );
      case 'split':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rec['name']?.toString() ?? 'Split',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (rec['session_definitions'] is List)
              ...((rec['session_definitions'] as List).map((sd) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${sd['label']} — ${(sd['muscle_groups'] as List?)?.join(', ') ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.zinc300,
                          ),
                        ),
                      ],
                    ),
                  ))),
          ],
        );
      case 'skeleton':
        final sessions = rec['sessions'] as List? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sessions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.zinc700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s['day_name']?.toString() ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.zinc300),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s['label']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.foreground,
                          ),
                        ),
                      ),
                      Text(
                        (s['muscle_groups'] as List?)?.join(', ') ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.zinc400,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      case 'roles':
        final roles = rec['roles'] as List? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rule: ${rec['assignment_rule']?.toString().replaceAll('_', ' ') ?? ''}',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.foreground,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...roles.take(3).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${r['session_label']} — ${(r['slots'] as List?)?.map((s) => s['role']).join(', ') ?? ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.zinc400),
                  ),
                )),
          ],
        );
      case 'structures':
        final structures = rec['structures'] as List? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: structures.take(6).map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  _RoleBadge(role: s['role']?.toString() ?? ''),
                  const SizedBox(width: 8),
                  Text(
                    '${s['sets']}x${s['reps']} @ ${s['rest_seconds']}s',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.foreground),
                  ),
                  const Spacer(),
                  Text(
                    s['modality']?.toString().replaceAll('-', ' ') ?? '',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.zinc400),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      case 'exercises':
        final exercises = rec['exercises'] as List? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: exercises.take(8).map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  _RoleBadge(role: e['slot_role']?.toString() ?? ''),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e['exercise_name']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.foreground),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${e['sets']}x${e['reps']}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.zinc400),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      case 'progression':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rec['profile']?.toString().replaceAll('_', ' ') ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              rec['description']?.toString() ?? '',
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.zinc300),
            ),
          ],
        );
      case 'publish':
        final preview = step.preview;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview['plan_name']?.toString() ?? 'Plan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${preview['total_weeks']} weeks, ${preview['total_sessions']} sessions',
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.zinc300),
            ),
          ],
        );
      default:
        return Text(
          rec.toString(),
          style: const TextStyle(fontSize: 13, color: AppTheme.zinc300),
        );
    }
  }

  Widget _buildPreview(Map<String, dynamic> preview) {
    if (preview.isEmpty) return const SizedBox.shrink();

    final entries = preview.entries
        .where((e) => e.value != null)
        .take(5)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current State',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key.replaceAll('_', ' '),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.zinc400),
                    ),
                    Text(
                      e.value.toString(),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.foreground,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCompleteView(BuilderStepResult step) {
    final preview = step.preview;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              step.why,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (preview['slots_created'] != null)
              Text(
                '${preview['slots_created']} exercise slots created',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.mutedForeground),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  context.push('/plan-detail/${step.planId}');
                },
                child: const Text('View Plan'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.foreground,
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool expand;

  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.zinc800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        alignment: expand ? Alignment.center : null,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.foreground : AppTheme.mutedForeground,
          ),
        ),
      ),
    );
    return child;
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  Color get _color {
    switch (role) {
      case 'primary_compound':
        return AppTheme.primary;
      case 'secondary_compound':
        return const Color(0xFF8B5CF6);
      case 'accessory':
        return const Color(0xFF22C55E);
      case 'isolation':
        return const Color(0xFFFBBF24);
      default:
        return AppTheme.zinc500;
    }
  }

  String get _label {
    switch (role) {
      case 'primary_compound':
        return 'P';
      case 'secondary_compound':
        return 'S';
      case 'accessory':
        return 'A';
      case 'isolation':
        return 'I';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
