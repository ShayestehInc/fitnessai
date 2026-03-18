import 'package:flutter/material.dart';

import 'shared/set_input_row.dart';
import 'shared/weight_suggestion_row.dart';

/// Pyramid ascending: weight increases each set, reps decrease.
/// Labels: "1 (Light)", "2 (Medium)", "3 (Heavy)", "4 (Peak)".
class PyramidAscendingLog extends StatefulWidget {
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;

  const PyramidAscendingLog({
    super.key,
    required this.onSetCompleted,
    required this.totalSets,
    required this.targetReps,
    required this.restSeconds,
    this.lastWeight,
    this.tempo,
    this.modalityDetails,
  });

  @override
  State<PyramidAscendingLog> createState() => _PyramidAscendingLogState();
}

class _PyramidAscendingLogState extends State<PyramidAscendingLog> {
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<bool> _completed;

  static const _labels = ['Light', 'Medium', 'Heavy', 'Peak', 'Peak+'];
  static const _weightMultipliers = [0.70, 0.80, 0.90, 1.00, 1.05];

  @override
  void initState() {
    super.initState();
    _weightControllers = List.generate(
      widget.totalSets,
      (_) => TextEditingController(),
    );
    _repsControllers = List.generate(
      widget.totalSets,
      (_) => TextEditingController(),
    );
    _completed = List.filled(widget.totalSets, false);
  }

  @override
  void dispose() {
    for (final c in _weightControllers) {
      c.dispose();
    }
    for (final c in _repsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double _multiplierForSet(int index) {
    if (index < _weightMultipliers.length) return _weightMultipliers[index];
    return 1.0 + (index - 3) * 0.05;
  }

  int _targetRepsForSet(int index) {
    final decrease = (index * 2).clamp(0, widget.targetReps - 1);
    return widget.targetReps - decrease;
  }

  String _labelForSet(int index) {
    if (index < _labels.length) return _labels[index];
    return 'Peak+';
  }

  void _onComplete(int index) {
    final weight =
        double.tryParse(_weightControllers[index].text) ?? widget.lastWeight ?? 0;
    final reps =
        int.tryParse(_repsControllers[index].text) ?? _targetRepsForSet(index);
    setState(() => _completed[index] = true);
    widget.onSetCompleted(index, weight, reps, 'working');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.totalSets; i++) ...[
          if (widget.lastWeight != null)
            WeightSuggestionRow(
              baseWeight: widget.lastWeight!,
              multiplier: _multiplierForSet(i),
              label: '${i + 1} (${_labelForSet(i)})',
            ),
          SetInputRow(
            setNumber: i + 1,
            setLabel: '${i + 1}',
            setType: 'working',
            weightController: _weightControllers[i],
            repsController: _repsControllers[i],
            isCompleted: _completed[i],
            targetWeight: widget.lastWeight != null
                ? widget.lastWeight! * _multiplierForSet(i)
                : null,
            targetReps: _targetRepsForSet(i),
            tempoDisplay: widget.tempo,
            onComplete: () => _onComplete(i),
            accentColor: Colors.green,
          ),
          if (i < widget.totalSets - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}
