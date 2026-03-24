import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../training_plans/presentation/providers/training_plan_provider.dart';

/// Bottom sheet for generating an AI-curated program for a trainee.
class CuratedBuildSheet extends ConsumerStatefulWidget {
  final int traineeId;
  final String traineeName;
  final String? currentGoal;

  const CuratedBuildSheet({
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
      builder: (_) => CuratedBuildSheet(
        traineeId: traineeId,
        traineeName: traineeName,
        currentGoal: currentGoal,
      ),
    );
  }

  @override
  ConsumerState<CuratedBuildSheet> createState() => _CuratedBuildSheetState();
}

class _CuratedBuildSheetState extends ConsumerState<CuratedBuildSheet> {
  String _goal = '';
  int _daysPerWeek = 0;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _taskId;
  String _progressStep = '';
  Timer? _pollTimer;

  static const _goalOptions = [
    MapEntry('', 'Use trainee profile'),
    MapEntry('build_muscle', 'Build Muscle'),
    MapEntry('strength', 'Strength'),
    MapEntry('fat_loss', 'Fat Loss'),
    MapEntry('endurance', 'Endurance'),
    MapEntry('recomp', 'Recomposition'),
    MapEntry('general_fitness', 'General Fitness'),
  ];

  @override
  void initState() {
    super.initState();
    _goal = widget.currentGoal ?? '';
  }

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
            'AI Program for ${widget.traineeName}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a personalized program using their full profile, '
            'lift history, feedback patterns, and pain history.',
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
        Text('Goal (optional override)', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _goal,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
          items: _goalOptions
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => setState(() => _goal = v ?? ''),
        ),
        const SizedBox(height: 16),
        Text('Days per week (0 = auto)', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: List.generate(6, (i) {
            final day = i + 2;
            final isSelected = _daysPerWeek == day;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 5 ? 6 : 0),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _daysPerWeek = _daysPerWeek == day ? 0 : day;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.15)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text('Trainer notes (optional)', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'E.g., "Focus on posterior chain, client has a vacation in 6 weeks"',
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
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Program'),
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

    final repo = ref.read(trainingPlanRepositoryProvider);
    final result = await repo.submitCuratedBuild(
      traineeId: widget.traineeId,
      overrideGoal: _goal.isNotEmpty ? _goal : null,
      overrideDaysPerWeek: _daysPerWeek > 0 ? _daysPerWeek : null,
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
        final data = result['data'];
        final planId = data is Map ? data['plan_id'] : null;

        if (planId != null) {
          Navigator.of(context).pop();
          if (context.mounted) {
            context.push('/training-plans/$planId');
          }
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
