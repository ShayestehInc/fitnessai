import 'package:flutter/material.dart';

import 'shared/set_input_row.dart';
import 'shared/tempo_display.dart';

/// Controlled eccentrics logging — standard sets with prominent tempo display.
class ControlledEccentricsLog extends StatefulWidget {
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;

  const ControlledEccentricsLog({
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
  State<ControlledEccentricsLog> createState() =>
      _ControlledEccentricsLogState();
}

class _ControlledEccentricsLogState extends State<ControlledEccentricsLog> {
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<bool> _completed;

  String get _tempo => widget.tempo ?? '4-1-1-1';

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
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TempoDisplay(tempo: _tempo),
        ),
        ...List.generate(widget.totalSets, (i) {
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
              tempoDisplay: _tempo,
              onComplete: () => _onComplete(i),
            ),
          );
        }),
      ],
    );
  }
}
