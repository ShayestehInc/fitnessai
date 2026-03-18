import 'package:flutter/material.dart';

import 'shared/set_input_row.dart';
import 'shared/weight_suggestion_row.dart';

/// Down sets: heavy "Top Sets" followed by lighter "Back-Off Sets".
/// Top sets use red accent; back-off sets use teal accent with reduced weight.
class DownSetsLog extends StatefulWidget {
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;

  const DownSetsLog({
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
  State<DownSetsLog> createState() => _DownSetsLogState();
}

class _DownSetsLogState extends State<DownSetsLog> {
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<bool> _completed;

  int get _topSetCount =>
      (widget.modalityDetails?['top_sets'] as int?) ??
      (widget.totalSets / 2).ceil();

  int get _backOffCount => widget.totalSets - _topSetCount;

  double get _backOffMultiplier =>
      (widget.modalityDetails?['back_off_percent'] as num?)?.toDouble() ?? 0.85;

  @override
  void initState() {
    super.initState();
    _weightControllers = List.generate(
      widget.totalSets, (_) => TextEditingController(),
    );
    _repsControllers = List.generate(
      widget.totalSets, (_) => TextEditingController(),
    );
    _completed = List.filled(widget.totalSets, false);
  }

  @override
  void dispose() {
    for (final c in _weightControllers) { c.dispose(); }
    for (final c in _repsControllers) { c.dispose(); }
    super.dispose();
  }

  void _onComplete(int index, String setType) {
    final weight =
        double.tryParse(_weightControllers[index].text) ?? widget.lastWeight ?? 0;
    final reps = int.tryParse(_repsControllers[index].text) ?? widget.targetReps;
    setState(() => _completed[index] = true);
    widget.onSetCompleted(index, weight, reps, setType);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'Top Sets', color: theme.colorScheme.error),
        const SizedBox(height: 4),
        for (int i = 0; i < _topSetCount; i++) ...[
          SetInputRow(
            setNumber: i + 1,
            setLabel: 'T${i + 1}',
            setType: 'top',
            weightController: _weightControllers[i],
            repsController: _repsControllers[i],
            isCompleted: _completed[i],
            targetWeight: widget.lastWeight,
            targetReps: widget.targetReps,
            tempoDisplay: widget.tempo,
            onComplete: () => _onComplete(i, 'top'),
          ),
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 8),
        _SectionHeader(label: 'Back-Off Sets', color: Colors.teal),
        const SizedBox(height: 4),
        for (int i = 0; i < _backOffCount; i++) ...[
          if (widget.lastWeight != null)
            WeightSuggestionRow(
              baseWeight: widget.lastWeight!,
              multiplier: _backOffMultiplier,
              label: 'Back-off ${i + 1}',
            ),
          SetInputRow(
            setNumber: _topSetCount + i + 1,
            setLabel: 'B${i + 1}',
            setType: 'back_off',
            weightController: _weightControllers[_topSetCount + i],
            repsController: _repsControllers[_topSetCount + i],
            isCompleted: _completed[_topSetCount + i],
            targetWeight: widget.lastWeight != null
                ? widget.lastWeight! * _backOffMultiplier
                : null,
            targetReps: widget.targetReps + 2,
            tempoDisplay: widget.tempo,
            onComplete: () => _onComplete(_topSetCount + i, 'back_off'),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: color,
      )),
    );
  }
}
