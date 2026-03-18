import 'package:flutter/material.dart';

import 'shared/micro_rest_timer.dart';
import 'shared/round_header.dart';
import 'shared/set_input_row.dart';

/// Circuit: multi-exercise rounds. Minimal rest between exercises,
/// full rest after each round completes.
class CircuitLog extends StatefulWidget {
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;
  final int totalSets; // rounds
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;

  const CircuitLog({
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
  State<CircuitLog> createState() => _CircuitLogState();
}

class _CircuitLogState extends State<CircuitLog> {
  late final List<String> _names;
  late final int _txRest;
  late final List<TextEditingController> _wCtrl;
  late final List<TextEditingController> _rCtrl;
  late final List<bool> _done;
  int? _txSlot;
  int? _roundRest;

  @override
  void initState() {
    super.initState();
    final raw = widget.modalityDetails?['exercise_names'];
    _names = raw is List ? raw.cast<String>() : const ['Exercise A', 'Exercise B', 'Exercise C'];
    _txRest = (widget.modalityDetails?['transition_rest'] as int?) ?? 5;
    final total = widget.totalSets * _names.length;
    _wCtrl = List.generate(total, (_) => TextEditingController());
    _rCtrl = List.generate(total, (_) => TextEditingController());
    _done = List.filled(total, false);
  }

  @override
  void dispose() {
    for (final c in _wCtrl) { c.dispose(); }
    for (final c in _rCtrl) { c.dispose(); }
    super.dispose();
  }

  int _f(int r, int e) => r * _names.length + e;

  bool _roundDone(int r) {
    for (int e = 0; e < _names.length; e++) {
      if (!_done[_f(r, e)]) return false;
    }
    return true;
  }

  void _onComplete(int round, int exIdx) {
    final flat = _f(round, exIdx);
    final w = double.tryParse(_wCtrl[flat].text) ?? widget.lastWeight ?? 0;
    final r = int.tryParse(_rCtrl[flat].text) ?? widget.targetReps;
    setState(() {
      _done[flat] = true;
      if (_roundDone(round) && round < widget.totalSets - 1) {
        _roundRest = round;
      } else if (!_roundDone(round) && exIdx < _names.length - 1) {
        _txSlot = flat;
      }
    });
    widget.onSetCompleted(flat, w, r, 'working');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < widget.totalSets; r++) ...[
          RoundHeader(
            currentRound: r + 1,
            totalRounds: widget.totalSets,
            isActive: !_roundDone(r),
            label: 'Circuit - Round ${r + 1} of ${widget.totalSets}',
          ),
          for (int e = 0; e < _names.length; e++) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 2),
              child: Text(_names[e], style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color,
              )),
            ),
            SetInputRow(
              setNumber: _f(r, e) + 1, setLabel: '${e + 1}', setType: 'working',
              weightController: _wCtrl[_f(r, e)],
              repsController: _rCtrl[_f(r, e)],
              isCompleted: _done[_f(r, e)],
              targetReps: widget.targetReps, tempoDisplay: widget.tempo,
              onComplete: () => _onComplete(r, e), accentColor: Colors.cyan,
            ),
            if (_txSlot == _f(r, e))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: MicroRestTimer(
                  durationSeconds: _txRest,
                  onComplete: () => setState(() => _txSlot = null),
                  color: Colors.cyan.shade700,
                ),
              ),
          ],
          if (_roundRest == r)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: MicroRestTimer(
                durationSeconds: widget.restSeconds,
                onComplete: () => setState(() => _roundRest = null),
                color: Colors.cyan,
              ),
            ),
          if (r < widget.totalSets - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
