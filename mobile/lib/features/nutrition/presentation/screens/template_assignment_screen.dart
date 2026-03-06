import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
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
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (templates) => _buildForm(context, templates),
      ),
    );
  }

  Widget _buildForm(
      BuildContext context, List<NutritionTemplateModel> templates) {
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
      items: templates.map((t) {
        final label = t.isSystem ? '${t.name} (System)' : t.name;
        return DropdownMenuItem(value: t, child: Text(label));
      }).toList(),
      onChanged: (value) => setState(() => _selectedTemplate = value),
    );
  }

  Widget _buildParameterFields() {
    return Column(
      children: [
        TextField(
          controller: _bodyWeightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Body Weight (lbs)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyFatController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Body Fat % (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mealsPerDayController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Meals Per Day',
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

    setState(() => _isSubmitting = true);

    final params = <String, dynamic>{
      'meals_per_day': int.tryParse(_mealsPerDayController.text) ?? 4,
    };
    final weight = double.tryParse(_bodyWeightController.text);
    if (weight != null) params['body_weight_lbs'] = weight;
    final bf = double.tryParse(_bodyFatController.text);
    if (bf != null) {
      params['body_fat_pct'] = bf;
      if (weight != null) {
        params['lbm_lbs'] = weight * (1 - bf / 100);
      }
    }

    final schedule = <String, dynamic>{
      'method': _scheduleMethod,
      if (_scheduleMethod == 'training_based') ...{
        'training_days': _trainingDayType,
        'rest_days': _restDayType,
      },
    };

    final repo = ref.read(nutritionTemplateRepositoryProvider);
    final result = await repo.createAssignment(
      traineeId: widget.traineeId,
      templateId: _selectedTemplate!.id,
      parameters: params,
      dayTypeSchedule: schedule,
      fatMode: _fatMode,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nutrition template assigned')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String? ?? 'Assignment failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
