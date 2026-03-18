import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';
import '../../../../shared/widgets/adaptive/adaptive_route.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/program_week_model.dart';
import '../providers/program_provider.dart';
import '../widgets/split_type_card.dart';
import '../widgets/goal_type_card.dart';
import '../widgets/custom_day_configurator.dart';
import '../widgets/step_indicator.dart';
import 'program_builder_screen.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Multi-step wizard for generating a program using the smart generator API.
class ProgramGeneratorScreen extends ConsumerStatefulWidget {
  const ProgramGeneratorScreen({super.key});

  @override
  ConsumerState<ProgramGeneratorScreen> createState() =>
      _ProgramGeneratorScreenState();
}

class _ProgramGeneratorScreenState
    extends ConsumerState<ProgramGeneratorScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Split type
  String? _splitType;

  // Step 2: Configuration
  String _difficulty = 'intermediate';
  String _goal = 'build_muscle';
  int _durationWeeks = 4;
  int _trainingDaysPerWeek = 4;
  List<CustomDayConfig> _customDayConfig = [];

  // Step 3: Preview / generation
  bool _isGenerating = false;
  bool _isModifying = false;
  String? _errorMessage;
  Map<String, dynamic>? _generatedData;
  String? _modificationSummary;
  final TextEditingController _modifyController = TextEditingController();

  static const _totalSteps = 3;

  @override
  void dispose() {
    _modifyController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _splitType != null;
      case 1:
        if (_splitType == 'custom') {
          return _customDayConfig.isNotEmpty &&
              _customDayConfig.every((d) => d.muscleGroups.isNotEmpty);
        }
        return true;
      case 2:
        return _generatedData != null;
      default:
        return false;
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    if (_currentStep < _totalSteps - 1) {
      final nextStep = _currentStep + 1;
      if (nextStep == 2) {
        _generateProgram();
      }
      _goToStep(nextStep);
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _syncCustomDayConfig() {
    if (_splitType != 'custom') return;

    final currentCount = _customDayConfig.length;
    if (currentCount == _trainingDaysPerWeek) return;

    if (_trainingDaysPerWeek > currentCount) {
      final newDays = List<CustomDayConfig>.from(_customDayConfig);
      for (int i = currentCount; i < _trainingDaysPerWeek; i++) {
        newDays.add(CustomDayConfig(
          dayName: 'day_${i + 1}',
          label: 'Day ${i + 1}',
          muscleGroups: [],
        ));
      }
      setState(() => _customDayConfig = newDays);
    } else {
      setState(() {
        _customDayConfig =
            _customDayConfig.sublist(0, _trainingDaysPerWeek);
      });
    }
  }

  Future<void> _generateProgram() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedData = null;
    });

    final repository = ref.read(programRepositoryProvider);
    final result = await repository.generateProgram(
      splitType: _splitType!,
      difficulty: _difficulty,
      goal: _goal,
      durationWeeks: _durationWeeks,
      trainingDaysPerWeek: _trainingDaysPerWeek,
      customDayConfig: _splitType == 'custom'
          ? _customDayConfig.map((d) => d.toJson()).toList()
          : null,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _generatedData = result['data'] as Map<String, dynamic>;
        _isGenerating = false;
      });
    } else {
      setState(() {
        _errorMessage =
            result['error']?.toString() ?? 'Failed to generate program';
        _isGenerating = false;
      });
    }
  }

  void _openInBuilder() {
    if (_generatedData == null) return;

    final data = _generatedData!;
    final schedule = data['schedule'] as Map<String, dynamic>?;

    List<ProgramWeek>? weeks;
    if (schedule != null) {
      final weeksList = schedule['weeks'] as List<dynamic>?;
      if (weeksList != null) {
        weeks = weeksList
            .map((w) => ProgramWeek.fromJson(w as Map<String, dynamic>))
            .toList();
      }
    }

    Navigator.push(
      context,
      adaptivePageRoute(
        builder: (context) => ProgramBuilderScreen(
          templateName: data['name'] as String? ?? 'Generated Program',
          templateDescription: data['description'] as String?,
          durationWeeks: data['duration_weeks'] as int? ?? _durationWeeks,
          difficulty: data['difficulty_level'] as String? ?? _difficulty,
          goal: data['goal_type'] as String? ?? _goal,
          existingWeeks: weeks,
        ),
      ),
    );
  }

  Future<void> _modifyProgram() async {
    final text = _modifyController.text.trim();
    if (text.isEmpty || _generatedData == null || _isModifying) return;

    setState(() {
      _isModifying = true;
      _modificationSummary = null;
    });

    final repository = ref.read(programRepositoryProvider);
    final result = await repository.modifyProgram(
      modificationRequest: text,
      currentProgram: _generatedData!,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _generatedData = {
          ..._generatedData!,
          'name': data['name'] ?? _generatedData!['name'],
          'description': data['description'] ?? _generatedData!['description'],
          'schedule': data['schedule'] ?? _generatedData!['schedule'],
          'nutrition_template': data['nutrition_template'] ?? _generatedData!['nutrition_template'],
        };
        _modificationSummary = data['modification_summary'] as String?;
        _isModifying = false;
        _modifyController.clear();
      });
    } else {
      setState(() {
        _isModifying = false;
        _modificationSummary = 'Modification failed: ${result['error']}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.programsGenerateProgram),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: _onBack,
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          StepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            labels: const ['Split Type', 'Configure', 'Preview'],
          ),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSplitTypeStep(),
                _buildConfigStep(),
                _buildPreviewStep(),
              ],
            ),
          ),
          // Bottom navigation
          if (_currentStep < 2)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canProceed ? _onNext : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentStep == 1 ? 'Generate Program' : 'Next',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 1: Split Type ───

  Widget _buildSplitTypeStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Choose Your Split',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'How do you want to structure the training week?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        ...splitTypeOptions.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SplitTypeCard(
              option: option,
              selected: _splitType == option.key,
              onTap: () => setState(() => _splitType = option.key),
            ),
          );
        }),
      ],
    );
  }

  // ─── Step 2: Configuration ───

  Widget _buildConfigStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Difficulty
        Text(
          'Difficulty Level',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['beginner', 'intermediate', 'advanced'].map((level) {
            final isSelected = _difficulty == level;
            final label = level[0].toUpperCase() + level.substring(1);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 13)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _difficulty = level),
                  selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Goal
        Text(
          'Training Goal',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...goalTypeOptions.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GoalTypeCard(
              option: option,
              selected: _goal == option.key,
              onTap: () => setState(() => _goal = option.key),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Duration
        Text(
          'Program Duration',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _durationWeeks > 1
                  ? () => setState(() => _durationWeeks--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: context.l10n.programsDecreaseDuration,
            ),
            Expanded(
              child: Center(
                child: Semantics(
                  label: context.l10n.programsProgramDurationDurationWeeksWeeks,
                  child: Text(
                    '$_durationWeeks weeks',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _durationWeeks < 52
                  ? () => setState(() => _durationWeeks++)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: context.l10n.programsIncreaseDuration,
            ),
          ],
        ),
        Slider.adaptive(
          value: _durationWeeks.toDouble(),
          min: 1,
          max: 52,
          divisions: 51,
          label: '$_durationWeeks weeks',
          onChanged: (value) {
            setState(() => _durationWeeks = value.round());
          },
        ),

        const SizedBox(height: 24),

        // Training days per week
        Text(
          'Training Days / Week',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _trainingDaysPerWeek > 2
                  ? () {
                      setState(() => _trainingDaysPerWeek--);
                      _syncCustomDayConfig();
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: context.l10n.programsDecreaseTrainingDays,
            ),
            Expanded(
              child: Center(
                child: Semantics(
                  label: context.l10n.programsTrainingDaysPerWeekTrainingDaysPerWeek,
                  child: Text(
                    '$_trainingDaysPerWeek days',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _trainingDaysPerWeek < 7
                  ? () {
                      setState(() => _trainingDaysPerWeek++);
                      _syncCustomDayConfig();
                    }
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: context.l10n.programsIncreaseTrainingDays,
            ),
          ],
        ),
        Slider.adaptive(
          value: _trainingDaysPerWeek.toDouble(),
          min: 2,
          max: 7,
          divisions: 5,
          label: '$_trainingDaysPerWeek days',
          onChanged: (value) {
            setState(() => _trainingDaysPerWeek = value.round());
            _syncCustomDayConfig();
          },
        ),

        // Custom day configuration
        if (_splitType == 'custom') ...[
          const SizedBox(height: 24),
          CustomDayConfigurator(
            days: _customDayConfig,
            onChanged: (updated) =>
                setState(() => _customDayConfig = updated),
          ),
        ],
      ],
    );
  }

  // ─── Step 3: Preview ───

  Widget _buildPreviewStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AdaptiveSpinner(),
            const SizedBox(height: 24),
            Text(
              'Generating your program...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Selecting exercises and building your schedule',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Generation Failed',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => _goToStep(1),
                    child: Text(context.l10n.commonBack),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _generateProgram,
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_generatedData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Waiting for program data...',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Go back and try generating again.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _generateProgram,
                child: Text(context.l10n.programsGenerate),
              ),
            ],
          ),
        ),
      );
    }

    final data = _generatedData!;
    final name = data['name'] as String? ?? 'Generated Program';
    final description = data['description'] as String? ?? '';
    final schedule = data['schedule'] as Map<String, dynamic>?;
    final weeksList = schedule?['weeks'] as List<dynamic>? ?? [];

    // v6.5 metadata
    final progressionProfile = schedule?['progression_profile'] as String?;
    final periodizationStyle = schedule?['periodization_style'] as String?;
    final volumeSummary = schedule?['weekly_volume_summary'] as Map<String, dynamic>?;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(
                          theme,
                          _difficulty[0].toUpperCase() +
                              _difficulty.substring(1),
                          Icons.signal_cellular_alt,
                        ),
                        _buildInfoChip(
                          theme,
                          _goalLabel(_goal),
                          Icons.flag_outlined,
                        ),
                        _buildInfoChip(
                          theme,
                          '$_durationWeeks weeks',
                          Icons.calendar_today,
                        ),
                        _buildInfoChip(
                          theme,
                          '$_trainingDaysPerWeek days/wk',
                          Icons.repeat,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // v6.5: Progression & Periodization card
              if (progressionProfile != null || periodizationStyle != null) ...[
                const SizedBox(height: 12),
                _buildProgressionCard(theme, progressionProfile, periodizationStyle),
              ],

              // v6.5: Volume Summary card
              if (volumeSummary != null) ...[
                const SizedBox(height: 12),
                _buildVolumeSummaryCard(theme, volumeSummary),
              ],

              const SizedBox(height: 20),

              // Week preview
              Text(
                'Weekly Schedule (Week 1)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (weeksList.isNotEmpty) ...[
                _buildWeekPreview(
                  theme,
                  weeksList.first as Map<String, dynamic>,
                ),
              ],

              const SizedBox(height: 16),

              // Modification summary
              if (_modificationSummary != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _modificationSummary!.startsWith('Modification failed')
                        ? colorScheme.errorContainer.withValues(alpha: 0.3)
                        : colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _modificationSummary!.startsWith('Modification failed')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 18,
                        color: _modificationSummary!.startsWith('Modification failed')
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _modificationSummary!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 60),
            ],
          ),
        ),
        // Modify input + Open in Builder
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI modify input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _modifyController,
                        enabled: !_isModifying,
                        decoration: InputDecoration(
                          hintText: 'Modify program... e.g. "more squats in week 1"',
                          hintStyle: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: theme.textTheme.bodyMedium,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _modifyProgram(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isModifying
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            onPressed: _modifyController.text.trim().isNotEmpty
                                ? _modifyProgram
                                : null,
                            icon: Icon(Icons.send, color: colorScheme.primary),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 10),
                // Open in Builder button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openInBuilder,
                    icon: const Icon(Icons.edit),
                    label: Text(context.l10n.programsOpenInBuilder),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekPreview(ThemeData theme, Map<String, dynamic> weekData) {
    final days = (weekData['days'] as List<dynamic>?) ?? [];

    return Column(
      children: days.asMap().entries.map((entry) {
        final day = entry.value as Map<String, dynamic>;
        final dayName = day['name'] as String? ?? 'Day ${entry.key + 1}';
        final isRestDay = day['is_rest_day'] as bool? ?? false;
        final exercises = (day['exercises'] as List<dynamic>?) ?? [];
        final sessionRoles = (day['session_role_labels'] as List<dynamic>?) ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRestDay
                ? theme.dividerColor.withValues(alpha: 0.3)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isRestDay ? Icons.bed : Icons.fitness_center,
                    size: 18,
                    color: isRestDay
                        ? theme.textTheme.bodySmall?.color
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (sessionRoles.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            sessionRoles.join(' / '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (!isRestDay && exercises.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${exercises.length} exercises',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (isRestDay) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Recovery day',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // v6.5: Show exercise details with slot roles and set structures
              if (!isRestDay && exercises.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...exercises.map((e) {
                  final ex = e as Map<String, dynamic>;
                  return _buildExerciseRow(theme, ex);
                }),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExerciseRow(ThemeData theme, Map<String, dynamic> ex) {
    final name = ex['exercise_name'] as String? ?? '';
    final sets = ex['sets'] ?? 0;
    final reps = ex['reps'] ?? '';
    final slotRole = ex['slot_role'] as String?;
    final setStructure = ex['set_structure'] as String?;
    final tempo = ex['tempo'] as String?;
    final intensityPct = ex['intensity_target_pct'] as int?;
    final reason = ex['selection_reason'] as String?;

    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Slot role indicator
              if (slotRole != null)
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _slotRoleColor(theme, slotRole),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Sets x Reps
              Text(
                '${sets}x$reps',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          // v6.5 tags row
          if (slotRole != null || setStructure != null || tempo != null || intensityPct != null)
            Padding(
              padding: EdgeInsets.only(left: slotRole != null ? 11 : 0, top: 2),
              child: Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  if (slotRole != null)
                    _buildMicroTag(theme, _slotRoleLabel(slotRole), _slotRoleColor(theme, slotRole)),
                  if (setStructure != null && setStructure != 'straight_sets')
                    _buildMicroTag(theme, _setStructureLabel(setStructure), theme.colorScheme.tertiary),
                  if (tempo != null && tempo != '2-0-1-0')
                    _buildMicroTag(theme, 'Tempo $tempo', theme.colorScheme.secondary),
                  if (intensityPct != null)
                    _buildMicroTag(theme, '$intensityPct%', theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          // Selection reason
          if (reason != null && reason.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: slotRole != null ? 11 : 0, top: 2),
              child: Text(
                reason,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMicroTag(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProgressionCard(
    ThemeData theme,
    String? progressionProfile,
    String? periodizationStyle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progression Strategy',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  children: [
                    if (progressionProfile != null)
                      Text(
                        _progressionLabel(progressionProfile),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (periodizationStyle != null)
                      Text(
                        _periodizationLabel(periodizationStyle),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSummaryCard(ThemeData theme, Map<String, dynamic> summary) {
    final totalHardSets = summary['total_hard_sets'] as int?;
    final setsByMuscle = summary['sets_by_muscle_group'] as Map<String, dynamic>?;
    final patternCoverage = (summary['pattern_coverage'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                'Weekly Volume',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (totalHardSets != null) ...[
                const Spacer(),
                Text(
                  '$totalHardSets hard sets',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (setsByMuscle != null && setsByMuscle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: setsByMuscle.entries.map((e) {
                return _buildInfoChip(
                  theme,
                  '${e.key.replaceAll('_', ' ')}: ${e.value}',
                  Icons.circle,
                );
              }).toList(),
            ),
          ],
          if (patternCoverage != null && patternCoverage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Patterns: ${patternCoverage.map((p) => p.replaceAll('_', ' ')).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _slotRoleColor(ThemeData theme, String slotRole) {
    switch (slotRole) {
      case 'primary_compound': return theme.colorScheme.error;
      case 'secondary_compound': return theme.colorScheme.primary;
      case 'accessory': return theme.colorScheme.tertiary;
      case 'isolation': return theme.colorScheme.onSurfaceVariant;
      default: return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _slotRoleLabel(String slotRole) {
    switch (slotRole) {
      case 'primary_compound': return 'Primary';
      case 'secondary_compound': return 'Secondary';
      case 'accessory': return 'Accessory';
      case 'isolation': return 'Isolation';
      default: return slotRole;
    }
  }

  String _setStructureLabel(String structure) {
    switch (structure) {
      case 'straight_sets': return 'Straight Sets';
      case 'drop_sets': return 'Drop Sets';
      case 'supersets': return 'Supersets';
      case 'myo_reps': return 'Myo-Reps';
      case 'controlled_eccentrics': return 'Controlled Eccentrics';
      case 'down_sets': return 'Down Sets';
      case 'rest_pause': return 'Rest-Pause';
      default: return structure.replaceAll('_', ' ');
    }
  }

  String _progressionLabel(String profile) {
    switch (profile) {
      case 'staircase_percent': return 'Staircase %';
      case 'rep_staircase': return 'Rep Staircase';
      case 'wave_by_month': return 'Monthly Waves';
      case 'double_progression': return 'Double Progression';
      default: return profile.replaceAll('_', ' ');
    }
  }

  String _periodizationLabel(String style) {
    switch (style) {
      case 'DUP': return 'Daily Undulating';
      case 'WUP': return 'Weekly Undulating';
      case 'linear': return 'Linear';
      case 'block': return 'Block';
      case 'concurrent': return 'Concurrent';
      default: return style;
    }
  }

  String _goalLabel(String key) {
    for (final option in goalTypeOptions) {
      if (option.key == key) return option.label;
    }
    return key;
  }
}

