import 'package:flutter/material.dart';

import 'shared/set_input_row.dart';

/// Standard straight-sets logging — N uniform sets rendered vertically.
class StraightSetsLog extends StatefulWidget {
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;

  const StraightSetsLog({
    super.key,
    required this.totalSets,
    required this.targetReps,
    required this.restSeconds,
    required this.onSetCompleted,
    this.lastWeight,
    this.tempo,
    this.modalityDetails,
  });

  @override
  State<StraightSetsLog> createState() => _StraightSetsLogState();
}

class _StraightSetsLogState extends State<StraightSetsLog> {
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<bool> _completed;

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

  void _onComplete(int index) {
    final weight =
        double.tryParse(_weightControllers[index].text) ?? widget.lastWeight ?? 0;
    final reps =
        int.tryParse(_repsControllers[index].text) ?? widget.targetReps;
    setState(() => _completed[index] = true);
    widget.onSetCompleted(index, weight, reps, 'working');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.totalSets, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: SetInputRow(
            setNumber: i + 1,
            setLabel: '${i + 1}',
            setType: 'working',
            weightController: _weightControllers[i],
            repsController: _repsControllers[i],
            isCompleted: _completed[i],
            targetWeight: widget.lastWeight,
            targetReps: widget.targetReps,
            tempoDisplay: widget.tempo,
            onComplete: () => _onComplete(i),
          ),
        );
      }),
    );
  }
}
