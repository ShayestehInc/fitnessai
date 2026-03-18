import 'package:flutter/material.dart';

import 'shared/micro_rest_timer.dart';
import 'shared/set_input_row.dart';

/// Rest-pause logging — primary set to failure, micro-rests, continuation sets.
class RestPauseLog extends StatefulWidget {
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;

  const RestPauseLog({
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
  State<RestPauseLog> createState() => _RestPauseLogState();
}

class _RestPauseLogState extends State<RestPauseLog> {
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<bool> _completed;
  bool _showingRest = false;
  int _activeIndex = 0;

  int get _microRestSeconds =>
      widget.modalityDetails?['rest_seconds'] as int? ?? 12;

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

  String _label(int index) {
    if (index == 0) return 'Set 1';
    return 'RP$index';
  }

  void _onComplete(int index) {
    final weight =
        double.tryParse(_weightControllers[index].text) ?? widget.lastWeight ?? 0;
    final reps =
        int.tryParse(_repsControllers[index].text) ?? widget.targetReps;
    setState(() {
      _completed[index] = true;
      if (index < widget.totalSets - 1) {
        _showingRest = true;
      }
    });
    widget.onSetCompleted(index, weight, reps, index == 0 ? 'working' : 'mini');
  }

  void _onRestComplete() => setState(() { _showingRest = false; _activeIndex++; });

  int get _totalReps => _completed.indexed
      .where((e) => e.$2)
      .fold(0, (sum, e) => sum + (int.tryParse(_repsControllers[e.$1].text) ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleCount = _activeIndex + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < visibleCount && i < widget.totalSets; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: SetInputRow(
              setNumber: i + 1,
              setLabel: _label(i),
              setType: i == 0 ? 'working' : 'mini',
              weightController: _weightControllers[i],
              repsController: _repsControllers[i],
              isCompleted: _completed[i],
              targetWeight: widget.lastWeight,
              targetReps: i == 0 ? widget.targetReps : null,
              onComplete: () => _onComplete(i),
              accentColor: i == 0 ? theme.colorScheme.error : Colors.red[300],
            ),
          ),
        ],
        if (_showingRest)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: MicroRestTimer(
              durationSeconds: _microRestSeconds,
              onComplete: _onRestComplete,
              color: theme.colorScheme.error,
            ),
          ),
        if (_totalReps > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total reps: $_totalReps',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
