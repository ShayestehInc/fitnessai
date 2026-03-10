import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/feedback_provider.dart';
import '../widgets/pain_severity_slider.dart';

/// Pain event logging form. Can be used standalone or return a result
/// when embedded in the session feedback flow.
class PainLogScreen extends ConsumerStatefulWidget {
  /// When true, pops with the pain event data instead of submitting to API.
  final bool returnResult;
  final int? exerciseId;
  final int? activeSessionId;

  const PainLogScreen({
    super.key,
    this.returnResult = false,
    this.exerciseId,
    this.activeSessionId,
  });

  @override
  ConsumerState<PainLogScreen> createState() => _PainLogScreenState();
}

class _PainLogScreenState extends ConsumerState<PainLogScreen> {
  final _notesController = TextEditingController();

  String _bodyRegion = 'lower_back';
  int _painScore = 3;
  String? _side;
  String? _sensationType;
  String? _onsetPhase;
  String? _warmupEffect;
  bool _isSubmitting = false;

  static const List<_DropdownOption> _bodyRegions = [
    _DropdownOption(value: 'lower_back', label: 'Lower Back'),
    _DropdownOption(value: 'upper_back', label: 'Upper Back'),
    _DropdownOption(value: 'neck', label: 'Neck'),
    _DropdownOption(value: 'left_shoulder', label: 'Left Shoulder'),
    _DropdownOption(value: 'right_shoulder', label: 'Right Shoulder'),
    _DropdownOption(value: 'left_elbow', label: 'Left Elbow'),
    _DropdownOption(value: 'right_elbow', label: 'Right Elbow'),
    _DropdownOption(value: 'left_wrist', label: 'Left Wrist'),
    _DropdownOption(value: 'right_wrist', label: 'Right Wrist'),
    _DropdownOption(value: 'left_hip', label: 'Left Hip'),
    _DropdownOption(value: 'right_hip', label: 'Right Hip'),
    _DropdownOption(value: 'left_knee', label: 'Left Knee'),
    _DropdownOption(value: 'right_knee', label: 'Right Knee'),
    _DropdownOption(value: 'left_ankle', label: 'Left Ankle'),
    _DropdownOption(value: 'right_ankle', label: 'Right Ankle'),
    _DropdownOption(value: 'chest', label: 'Chest'),
    _DropdownOption(value: 'core', label: 'Core/Abdomen'),
    _DropdownOption(value: 'other', label: 'Other'),
  ];

  static const List<_DropdownOption> _sides = [
    _DropdownOption(value: 'left', label: 'Left'),
    _DropdownOption(value: 'right', label: 'Right'),
    _DropdownOption(value: 'bilateral', label: 'Both Sides'),
    _DropdownOption(value: 'central', label: 'Central'),
  ];

  static const List<_DropdownOption> _sensationTypes = [
    _DropdownOption(value: 'sharp', label: 'Sharp'),
    _DropdownOption(value: 'dull', label: 'Dull/Aching'),
    _DropdownOption(value: 'burning', label: 'Burning'),
    _DropdownOption(value: 'tingling', label: 'Tingling/Numbness'),
    _DropdownOption(value: 'stabbing', label: 'Stabbing'),
    _DropdownOption(value: 'throbbing', label: 'Throbbing'),
    _DropdownOption(value: 'tightness', label: 'Tightness'),
  ];

  static const List<_DropdownOption> _onsetPhases = [
    _DropdownOption(value: 'warmup', label: 'During Warmup'),
    _DropdownOption(value: 'working_sets', label: 'During Working Sets'),
    _DropdownOption(value: 'cooldown', label: 'During Cooldown'),
    _DropdownOption(value: 'between_sets', label: 'Between Sets'),
    _DropdownOption(value: 'post_workout', label: 'Post-Workout'),
    _DropdownOption(value: 'pre_existing', label: 'Pre-existing'),
  ];

  static const List<_DropdownOption> _warmupEffects = [
    _DropdownOption(value: 'resolved', label: 'Resolved with warmup'),
    _DropdownOption(value: 'improved', label: 'Improved but persisted'),
    _DropdownOption(value: 'no_change', label: 'No change'),
    _DropdownOption(value: 'worsened', label: 'Got worse'),
    _DropdownOption(value: 'not_applicable', label: 'Not applicable'),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Log Pain Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
              theme: theme,
              label: 'Body Region',
              value: _bodyRegion,
              options: _bodyRegions,
              onChanged: (v) => setState(() => _bodyRegion = v!),
            ),
            const SizedBox(height: 20),
            PainSeveritySlider(
              value: _painScore,
              onChanged: (v) => setState(() => _painScore = v),
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              theme: theme,
              label: 'Side',
              value: _side,
              options: _sides,
              onChanged: (v) => setState(() => _side = v),
              isOptional: true,
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              theme: theme,
              label: 'Sensation Type',
              value: _sensationType,
              options: _sensationTypes,
              onChanged: (v) => setState(() => _sensationType = v),
              isOptional: true,
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              theme: theme,
              label: 'When Did It Start?',
              value: _onsetPhase,
              options: _onsetPhases,
              onChanged: (v) => setState(() => _onsetPhase = v),
              isOptional: true,
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              theme: theme,
              label: 'Warmup Effect',
              value: _warmupEffect,
              options: _warmupEffects,
              onChanged: (v) => setState(() => _warmupEffect = v),
              isOptional: true,
            ),
            const SizedBox(height: 20),
            Text('Notes (optional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the pain or discomfort...',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const AdaptiveSpinner.small()
                    : const Text('Log Pain Event'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required ThemeData theme,
    required String label,
    required String? value,
    required List<_DropdownOption> options,
    required ValueChanged<String?> onChanged,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOptional ? '$label (optional)' : label,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text('Select $label'),
              items: [
                if (isOptional)
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                ...options.map((o) => DropdownMenuItem<String>(
                      value: o.value,
                      child: Text(o.label),
                    )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final eventData = <String, dynamic>{
      'body_region': _bodyRegion,
      'pain_score': _painScore,
      'notes': _notesController.text.trim(),
    };

    if (_side != null) eventData['side'] = _side;
    if (_sensationType != null) eventData['sensation_type'] = _sensationType;
    if (_onsetPhase != null) eventData['onset_phase'] = _onsetPhase;
    if (_warmupEffect != null) eventData['warmup_effect'] = _warmupEffect;
    if (widget.exerciseId != null) {
      eventData['exercise_id'] = widget.exerciseId;
    }
    if (widget.activeSessionId != null) {
      eventData['active_session_id'] = widget.activeSessionId;
    }

    if (widget.returnResult) {
      Navigator.of(context).pop(eventData);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(logPainEventProvider.notifier).log(
          bodyRegion: _bodyRegion,
          painScore: _painScore,
          side: _side,
          sensationType: _sensationType,
          onsetPhase: _onsetPhase,
          warmupEffect: _warmupEffect,
          exerciseId: widget.exerciseId,
          activeSessionId: widget.activeSessionId,
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    if (result != null) {
      showAdaptiveToast(
        context,
        message: 'Pain event logged.',
        type: ToastType.success,
      );
      context.pop();
    } else {
      setState(() => _isSubmitting = false);
      showAdaptiveToast(
        context,
        message: 'Failed to log pain event.',
        type: ToastType.error,
      );
    }
  }
}

class _DropdownOption {
  final String value;
  final String label;

  const _DropdownOption({required this.value, required this.label});
}
