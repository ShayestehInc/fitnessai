import 'package:flutter/material.dart';

import 'shared/set_input_row.dart';
import 'shared/weight_suggestion_row.dart';

/// Drop-set logging — top set followed by progressively lighter drops.
class DropSetLog extends StatefulWidget {
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;

  const DropSetLog({
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
  State<DropSetLog> createState() => _DropSetLogState();
}

class _DropSetLogState extends State<DropSetLog> {
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<bool> _completed;

  double get _dropPercent =>
      (widget.modalityDetails?['drop_percent'] as num?)?.toDouble() ?? 0.20;

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
    final setType = index == 0 ? 'top' : 'drop';
    final weight =
        double.tryParse(_weightControllers[index].text) ?? widget.lastWeight ?? 0;
    final reps =
        int.tryParse(_repsControllers[index].text) ?? widget.targetReps;
    setState(() => _completed[index] = true);
    widget.onSetCompleted(index, weight, reps, setType);
  }

  double _multiplierForDrop(int dropIndex) => 1.0 - (_dropPercent * dropIndex);

  @override
  Widget build(BuildContext context) {
    final baseWeight = widget.lastWeight ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.totalSets, (i) {
        final isTop = i == 0;
        final label = isTop ? 'TOP' : 'D$i';
        final setType = isTop ? 'top' : 'drop';
        final color = isTop ? Colors.red : Colors.orange;

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isTop && baseWeight > 0)
                WeightSuggestionRow(
                  baseWeight: baseWeight,
                  multiplier: _multiplierForDrop(i),
                  label: 'Drop $i (-${(_dropPercent * i * 100).round()}%)',
                ),
              SetInputRow(
                setNumber: i + 1,
                setLabel: label,
                setType: setType,
                weightController: _weightControllers[i],
                repsController: _repsControllers[i],
                isCompleted: _completed[i],
                targetWeight: isTop
                    ? widget.lastWeight
                    : (baseWeight > 0
                        ? baseWeight * _multiplierForDrop(i)
                        : null),
                targetReps: widget.targetReps,
                onComplete: () => _onComplete(i),
                accentColor: color,
              ),
            ],
          ),
        );
      }),
    );
  }
}
