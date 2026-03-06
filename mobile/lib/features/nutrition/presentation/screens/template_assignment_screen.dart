import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/nutrition_template_models.dart';
import '../providers/nutrition_template_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

class TemplateAssignmentScreen extends ConsumerStatefulWidget {
  final int traineeId;

  const TemplateAssignmentScreen({super.key, required this.traineeId});

  @override
  ConsumerState<TemplateAssignmentScreen> createState() =>
      _TemplateAssignmentScreenState();
}

class _TemplateAssignmentScreenState
    extends ConsumerState<TemplateAssignmentScreen> {
  NutritionTemplateModel? _selectedTemplate;
  String _fatMode = 'total_fat';
  String _scheduleMethod = 'training_based';
  String _trainingDayType = 'training';
  String _restDayType = 'rest';
  bool _isSubmitting = false;

  final _bodyWeightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _mealsPerDayController = TextEditingController(text: '4');

  @override
  void dispose() {
    _bodyWeightController.dispose();
    _bodyFatController.dispose();
    _mealsPerDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(nutritionTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.nutritionAssignNutritionTemplate),
      ),
      body: PopScope(
        canPop: !_isSubmitting,
        child: templatesAsync.when(
          loading: () => Center(
            child: Semantics(
              label: context.l10n.nutritionLoadingNutritionTemplates,
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load templates.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () =>
                        ref.invalidate(nutritionTemplatesProvider),
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
          data: (templates) => _buildForm(context, templates),
        ),
      ),
    );
  }

  Widget _buildForm(
      BuildContext context, List<NutritionTemplateModel> templates) {
    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No templates available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Create one from the web dashboard first.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.nutritionTemplate,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildTemplateSelector(templates),
          const SizedBox(height: 24),
          Text(context.l10n.nutritionTraineeParameters,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildParameterFields(),
          const SizedBox(height: 24),
          Text(context.l10n.nutritionDayTypeSchedule,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildScheduleConfig(),
          const SizedBox(height: 24),
          Text(context.l10n.nutritionFatMode,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildFatModeSelector(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedTemplate == null || _isSubmitting
                  ? null
                  : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.nutritionAssignTemplate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector(List<NutritionTemplateModel> templates) {
    return DropdownButtonFormField<NutritionTemplateModel>(
      value: _selectedTemplate,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: context.l10n.nutritionSelectATemplate,
      ),
      isExpanded: true,
      items: templates.map((t) {
        final suffix = t.isSystem ? ' (System)' : '';
        return DropdownMenuItem(
          value: t,
          child: Text(
            '${t.name}$suffix',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedTemplate = value),
    );
  }

  Widget _buildParameterFields() {
    return Column(
      children: [
        TextField(
          controller: _bodyWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.l10n.nutritionBodyWeightLbs,
            helperText: context.l10n.nutritionRequiredUsedToCalculateMacroTargets,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyFatController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.l10n.nutritionBodyFatOptional,
            helperText: context.l10n.nutritionIfKnownImprovesLeanBodyMassCalculation,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mealsPerDayController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.onboardingMealsPerDay,
            helperText: context.l10n.nutritionBetween1And10,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleConfig() {
    return Column(
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'training_based', label: Text(context.l10n.nutritionTrainingBased)),
            ButtonSegment(
                value: 'weekly_rotation', label: Text(context.l10n.nutritionWeeklyRotation)),
          ],
          selected: {_scheduleMethod},
          onSelectionChanged: (v) =>
              setState(() => _scheduleMethod = v.first),
        ),
        if (_scheduleMethod == 'training_based') ...[
          const SizedBox(height: 12),
          _buildDayTypeDropdown(
            'Training Days',
            _trainingDayType,
            (v) => setState(() => _trainingDayType = v!),
          ),
          const SizedBox(height: 8),
          _buildDayTypeDropdown(
            'Rest Days',
            _restDayType,
            (v) => setState(() => _restDayType = v!),
          ),
        ],
        if (_scheduleMethod == 'weekly_rotation') ...[
          const SizedBox(height: 12),
          Text(
            'Day types will rotate automatically across the week based on the template configuration.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayTypeDropdown(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    const dayTypes = [
      ('training', 'Training'),
      ('rest', 'Rest'),
      ('high_carb', 'High Carb'),
      ('medium_carb', 'Medium Carb'),
      ('low_carb', 'Low Carb'),
      ('refeed', 'Refeed'),
    ];

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: dayTypes
          .map((dt) => DropdownMenuItem(value: dt.$1, child: Text(dt.$2)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildFatModeSelector() {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'total_fat', label: Text(context.l10n.nutritionTotalFat)),
        ButtonSegment(value: 'added_fat', label: Text(context.l10n.nutritionAddedFat)),
      ],
      selected: {_fatMode},
      onSelectionChanged: (v) => setState(() => _fatMode = v.first),
    );
  }

  Future<void> _submit() async {
    if (_selectedTemplate == null) return;

    final weight = double.tryParse(_bodyWeightController.text.trim());
    if (weight == null || weight <= 0 || weight > 1000) {
      String message;
      if (weight == null || _bodyWeightController.text.trim().isEmpty) {
        message = context.l10n.nutritionBodyWeightIsRequired;
      } else if (weight <= 0) {
        message = context.l10n.nutritionBodyWeightMustBeAPositiveNumber;
      } else {
        message = context.l10n.nutritionBodyWeightMustBeUnder1000Lbs;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final bfText = _bodyFatController.text.trim();
    if (bfText.isNotEmpty) {
      final bfVal = double.tryParse(bfText);
      if (bfVal == null || bfVal < 1 || bfVal > 70) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.nutritionBodyFatMustBeBetween1And70),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    final mealsPerDay = int.tryParse(_mealsPerDayController.text.trim());
    if (mealsPerDay == null || mealsPerDay < 1 || mealsPerDay > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.nutritionMealsPerDayMustBeBetween1And10),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final params = <String, dynamic>{
      'meals_per_day': mealsPerDay,
      'body_weight_lbs': weight,
    };
    final bf = double.tryParse(_bodyFatController.text.trim());
    if (bf != null) {
      params['body_fat_pct'] = bf;
      params['lbm_lbs'] = weight * (1 - bf / 100);
    }

    final schedule = <String, dynamic>{
      'method': _scheduleMethod,
      if (_scheduleMethod == 'training_based') ...{
        'training_days': _trainingDayType,
        'rest_days': _restDayType,
      },
    };

    final repo = ref.read(nutritionTemplateRepositoryProvider);
    try {
      await repo.createAssignment(
        traineeId: widget.traineeId,
        templateId: _selectedTemplate!.id,
        parameters: params,
        dayTypeSchedule: schedule,
        fatMode: _fatMode,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(context.l10n.nutritionNutritionTemplateAssigned),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      context.pop();
    } on Exception {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.nutritionFailedToAssignTemplatePleaseTryAgain),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
