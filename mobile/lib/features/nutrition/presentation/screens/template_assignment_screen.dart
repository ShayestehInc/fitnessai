import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/nutrition_template_models.dart';
import '../providers/nutrition_template_provider.dart';

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
        title: const Text('Assign Nutrition Template'),
      ),
      body: PopScope(
        canPop: !_isSubmitting,
        child: templatesAsync.when(
          loading: () => Center(
            child: Semantics(
              label: 'Loading nutrition templates',
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
                    child: const Text('Retry'),
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
          Text('Template',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildTemplateSelector(templates),
          const SizedBox(height: 24),
          Text('Trainee Parameters',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildParameterFields(),
          const SizedBox(height: 24),
          Text('Day-Type Schedule',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildScheduleConfig(),
          const SizedBox(height: 24),
          Text('Fat Mode',
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
                  : const Text('Assign Template'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector(List<NutritionTemplateModel> templates) {
    return DropdownButtonFormField<NutritionTemplateModel>(
      value: _selectedTemplate,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Select a template',
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
          decoration: const InputDecoration(
            labelText: 'Body Weight (lbs)',
            helperText: 'Required. Used to calculate macro targets.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyFatController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Body Fat % (optional)',
            helperText: 'If known, improves lean body mass calculation.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mealsPerDayController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Meals Per Day',
            helperText: 'Between 1 and 10.',
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
          segments: const [
            ButtonSegment(
                value: 'training_based', label: Text('Training-Based')),
            ButtonSegment(
                value: 'weekly_rotation', label: Text('Weekly Rotation')),
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
      segments: const [
        ButtonSegment(value: 'total_fat', label: Text('Total Fat')),
        ButtonSegment(value: 'added_fat', label: Text('Added Fat')),
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
        message = 'Body weight is required';
      } else if (weight <= 0) {
        message = 'Body weight must be a positive number';
      } else {
        message = 'Body weight must be under 1,000 lbs';
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
            content: const Text('Body fat % must be between 1 and 70'),
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
          content: const Text('Meals per day must be between 1 and 10'),
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
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Nutrition template assigned'),
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
          content: const Text('Failed to assign template. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
