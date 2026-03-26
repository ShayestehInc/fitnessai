import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../nutrition/presentation/providers/nutrition_template_provider.dart';
import '../../../training_plans/presentation/providers/training_plan_provider.dart';
import '../providers/trainer_provider.dart';

/// Bottom sheet for generating an AI-curated nutrition plan for a trainee.
class CuratedNutritionSheet extends ConsumerStatefulWidget {
  final int traineeId;
  final String traineeName;
  final String? currentGoal;

  const CuratedNutritionSheet({
    super.key,
    required this.traineeId,
    required this.traineeName,
    this.currentGoal,
  });

  static Future<void> show(
    BuildContext context, {
    required int traineeId,
    required String traineeName,
    String? currentGoal,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CuratedNutritionSheet(
        traineeId: traineeId,
        traineeName: traineeName,
        currentGoal: currentGoal,
      ),
    );
  }

  @override
  ConsumerState<CuratedNutritionSheet> createState() =>
      _CuratedNutritionSheetState();
}

class _CuratedNutritionSheetState
    extends ConsumerState<CuratedNutritionSheet> {
  String _templateType = '';
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _taskId;
  String _progressStep = '';
  Timer? _pollTimer;

  static const _templateOptions = [
    MapEntry('', 'Auto (AI selects)'),
    MapEntry('shredded', 'SHREDDED (Fat Loss)'),
    MapEntry('massive', 'MASSIVE (Muscle Gain)'),
    MapEntry('carb_cycling', 'Carb Cycling (Flexible)'),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AI Nutrition Plan for ${widget.traineeName}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a personalized nutrition plan using their profile, '
            'training schedule, weight trends, and meal adherence.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (_isSubmitting) ...[
            _buildProgressView(theme),
          ] else ...[
            _buildForm(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Template type', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _templateType,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
          items: _templateOptions
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => setState(() => _templateType = v ?? ''),
        ),
        const SizedBox(height: 16),
        Text('Trainer notes (optional)', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText:
                'E.g., "Client prefers 5 meals, avoid dairy, needs higher protein"',
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Generate Nutrition Plan'),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressView(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        const AdaptiveSpinner(),
        const SizedBox(height: 16),
        Text(
          _progressStep.isNotEmpty
              ? _progressStep
              : 'Analyzing trainee data...',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final repo = ref.read(nutritionTemplateRepositoryProvider);
    final result = await repo.submitCuratedNutritionBuild(
      traineeId: widget.traineeId,
      overrideTemplateType:
          _templateType.isNotEmpty ? _templateType : null,
      trainerNotes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _taskId = result['task_id'] as String;
      _startPolling();
    } else {
      setState(() => _isSubmitting = false);
      showAdaptiveToast(
        context,
        message: result['error'] as String? ?? 'Failed to start build',
        type: ToastType.error,
      );
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_taskId == null) return;

      // Reuse the same task status endpoint
      final repo = ref.read(trainingPlanRepositoryProvider);
      final result = await repo.getQuickBuildStatus(_taskId!);

      if (!mounted) return;

      final taskStatus = result['status'] as String?;

      if (result.containsKey('progress_step')) {
        setState(() {
          _progressStep = result['progress_step'] as String? ?? '';
        });
      }

      if (taskStatus == 'completed') {
        _pollTimer?.cancel();

        // Extract result details
        final resultData = result['data'];
        String templateName = '';
        String reasoning = '';
        if (resultData is Map) {
          final inner = resultData['result'] ?? resultData;
          if (inner is Map) {
            templateName = inner['template_name']?.toString() ?? '';
            reasoning = inner['reasoning']?.toString() ?? '';
          }
        }

        // Invalidate providers so the Nutrition tab refreshes with new data
        ref.invalidate(traineeActiveAssignmentProvider(widget.traineeId));
        ref.invalidate(traineeDetailProvider(widget.traineeId));

        setState(() {
          _isSubmitting = false;
          _progressStep = '';
        });

        // Show result in the sheet instead of just closing
        if (mounted) {
          Navigator.of(context).pop();
          showAdaptiveToast(
            context,
            message: templateName.isNotEmpty
                ? '$templateName plan assigned!'
                : 'Nutrition plan generated successfully!',
            type: ToastType.success,
          );
        }
      } else if (taskStatus == 'failed') {
        _pollTimer?.cancel();
        setState(() => _isSubmitting = false);
        showAdaptiveToast(
          context,
          message: result['error'] as String? ?? 'Build failed',
          type: ToastType.error,
        );
      }
    });
  }
}
