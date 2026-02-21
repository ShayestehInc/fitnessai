import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/program_week_model.dart';
import '../providers/program_provider.dart';
import '../widgets/split_type_card.dart';
import '../widgets/goal_type_card.dart';
import '../widgets/custom_day_configurator.dart';
import '../widgets/step_indicator.dart';
import 'program_builder_screen.dart';

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
  String? _errorMessage;
  Map<String, dynamic>? _generatedData;

  static const _totalSteps = 3;

  @override
  void dispose() {
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
      MaterialPageRoute(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Program'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
              tooltip: 'Decrease duration',
            ),
            Expanded(
              child: Center(
                child: Semantics(
                  label: 'Program duration: $_durationWeeks weeks',
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
              tooltip: 'Increase duration',
            ),
          ],
        ),
        Slider(
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
              tooltip: 'Decrease training days',
            ),
            Expanded(
              child: Center(
                child: Semantics(
                  label: 'Training days per week: $_trainingDaysPerWeek',
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
              tooltip: 'Increase training days',
            ),
          ],
        ),
        Slider(
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
            const CircularProgressIndicator(),
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
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _generateProgram,
                    child: const Text('Retry'),
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
                child: const Text('Generate'),
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
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openInBuilder,
                icon: const Icon(Icons.edit),
                label: const Text('Open in Builder'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
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

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRestDay
                ? theme.dividerColor.withValues(alpha: 0.3)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
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
                    if (!isRestDay && exercises.isNotEmpty) ...[
                      const SizedBox(height: 4),
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
        );
      }).toList(),
    );
  }

  String _goalLabel(String key) {
    for (final option in goalTypeOptions) {
      if (option.key == key) return option.label;
    }
    return key;
  }
}

