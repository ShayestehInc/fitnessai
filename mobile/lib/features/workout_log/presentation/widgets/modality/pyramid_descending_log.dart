import 'package:flutter/material.dart';

import 'shared/set_input_row.dart';
import 'shared/weight_suggestion_row.dart';

/// Pyramid descending: weight decreases each set, reps increase.
/// Labels: "1 (Heavy)", "2 (Medium)", "3 (Light)".
class PyramidDescendingLog extends StatefulWidget {
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;

  const PyramidDescendingLog({
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
  State<PyramidDescendingLog> createState() => _PyramidDescendingLogState();
}

class _PyramidDescendingLogState extends State<PyramidDescendingLog> {
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<bool> _completed;

  static const _labels = ['Heavy', 'Medium', 'Light', 'Feather'];
  static const _weightMultipliers = [1.00, 0.85, 0.70, 0.60];

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
    return 0.60 - (index - 3) * 0.05;
  }

  int _targetRepsForSet(int index) {
    return widget.targetReps + (index * 2);
  }

  String _labelForSet(int index) {
    if (index < _labels.length) return _labels[index];
    return 'Light';
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
            accentColor: Colors.lightGreen,
          ),
          if (i < widget.totalSets - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}
