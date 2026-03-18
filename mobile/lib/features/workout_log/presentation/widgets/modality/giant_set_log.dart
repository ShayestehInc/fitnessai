import 'package:flutter/material.dart';

import 'shared/micro_rest_timer.dart';
import 'shared/round_header.dart';
import 'shared/set_input_row.dart';

/// Giant set: 3-4 exercises per round, no rest between exercises,
/// full rest after the round completes.
class GiantSetLog extends StatefulWidget {
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;
  final int totalSets; // rounds
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;

  const GiantSetLog({
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
  State<GiantSetLog> createState() => _GiantSetLogState();
}

class _GiantSetLogState extends State<GiantSetLog> {
  late final List<String> _exerciseNames;
  late final int _totalSlots;
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<bool> _completed;
  int? _restingAfterRound;

  @override
  void initState() {
    super.initState();
    final raw = widget.modalityDetails?['exercise_names'];
    _exerciseNames = raw is List
        ? raw.cast<String>()
        : const ['Exercise A', 'Exercise B', 'Exercise C'];
    _totalSlots = widget.totalSets * _exerciseNames.length;
    _weightControllers = List.generate(
      _totalSlots, (_) => TextEditingController(),
    );
    _repsControllers = List.generate(
      _totalSlots, (_) => TextEditingController(),
    );
    _completed = List.filled(_totalSlots, false);
  }

  @override
  void dispose() {
    for (final c in _weightControllers) { c.dispose(); }
    for (final c in _repsControllers) { c.dispose(); }
    super.dispose();
  }

  int _flat(int round, int ex) => round * _exerciseNames.length + ex;

  bool _isRoundComplete(int round) {
    for (int e = 0; e < _exerciseNames.length; e++) {
      if (!_completed[_flat(round, e)]) return false;
    }
    return true;
  }

  void _onComplete(int round, int exIdx) {
    final flat = _flat(round, exIdx);
    final weight =
        double.tryParse(_weightControllers[flat].text) ?? widget.lastWeight ?? 0;
    final reps =
        int.tryParse(_repsControllers[flat].text) ?? widget.targetReps;
    setState(() {
      _completed[flat] = true;
      if (_isRoundComplete(round) && round < widget.totalSets - 1) {
        _restingAfterRound = round;
      }
    });
    widget.onSetCompleted(flat, weight, reps, 'working');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exCount = _exerciseNames.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < widget.totalSets; r++) ...[
          RoundHeader(
            currentRound: r + 1,
            totalRounds: widget.totalSets,
            isActive: !_isRoundComplete(r),
            label: 'Giant Set - Round ${r + 1} of ${widget.totalSets}',
          ),
          for (int e = 0; e < exCount; e++) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 2),
              child: Text(
                _exerciseNames[e],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            SetInputRow(
              setNumber: _flat(r, e) + 1,
              setLabel: '${e + 1}',
              setType: 'working',
              weightController: _weightControllers[_flat(r, e)],
              repsController: _repsControllers[_flat(r, e)],
              isCompleted: _completed[_flat(r, e)],
              targetReps: widget.targetReps,
              tempoDisplay: widget.tempo,
              onComplete: () => _onComplete(r, e),
              accentColor: Colors.purple,
            ),
          ],
          if (_restingAfterRound == r)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: MicroRestTimer(
                durationSeconds: widget.restSeconds,
                onComplete: () => setState(() => _restingAfterRound = null),
                color: Colors.purple,
              ),
            ),
          if (r < widget.totalSets - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
