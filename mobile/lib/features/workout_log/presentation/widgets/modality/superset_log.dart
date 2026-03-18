import 'package:flutter/material.dart';

import 'shared/round_header.dart';
import 'shared/set_input_row.dart';

/// Superset logging — alternates between two exercises per round.
class SupersetLog extends StatefulWidget {
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;
  final String exerciseAName;
  final String exerciseBName;
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;

  const SupersetLog({
    super.key,
    required this.totalSets,
    required this.targetReps,
    required this.restSeconds,
    required this.onSetCompleted,
    required this.exerciseAName,
    required this.exerciseBName,
    this.lastWeight,
    this.tempo,
    this.modalityDetails,
  });

  @override
  State<SupersetLog> createState() => _SupersetLogState();
}

class _SupersetLogState extends State<SupersetLog> {
  late final List<TextEditingController> _weightA;
  late final List<TextEditingController> _repsA;
  late final List<TextEditingController> _weightB;
  late final List<TextEditingController> _repsB;
  late final List<bool> _completedA;
  late final List<bool> _completedB;

  @override
  void initState() {
    super.initState();
    final n = widget.totalSets;
    _weightA = List.generate(n, (_) => TextEditingController());
    _repsA = List.generate(n, (_) => TextEditingController());
    _weightB = List.generate(n, (_) => TextEditingController());
    _repsB = List.generate(n, (_) => TextEditingController());
    _completedA = List.filled(n, false);
    _completedB = List.filled(n, false);
  }

  @override
  void dispose() {
    for (final list in [_weightA, _repsA, _weightB, _repsB]) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _complete(bool isA, int round) {
    final wCtrl = isA ? _weightA[round] : _weightB[round];
    final rCtrl = isA ? _repsA[round] : _repsB[round];
    final weight = double.tryParse(wCtrl.text) ?? widget.lastWeight ?? 0;
    final reps = int.tryParse(rCtrl.text) ?? widget.targetReps;
    setState(() {
      if (isA) {
        _completedA[round] = true;
      } else {
        _completedB[round] = true;
      }
    });
    final globalIndex = isA ? round * 2 : round * 2 + 1;
    widget.onSetCompleted(globalIndex, weight, reps, 'working');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeRound = _completedB.indexWhere((c) => !c);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.totalSets, (round) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoundHeader(
                currentRound: round + 1,
                totalRounds: widget.totalSets,
                isActive: round == activeRound,
              ),
              SetInputRow(
                setNumber: round * 2 + 1,
                setLabel: 'A',
                weightController: _weightA[round],
                repsController: _repsA[round],
                isCompleted: _completedA[round],
                targetReps: widget.targetReps,
                targetWeight: widget.lastWeight,
                onComplete: () => _complete(true, round),
                accentColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 2),
              SetInputRow(
                setNumber: round * 2 + 2,
                setLabel: 'B',
                weightController: _weightB[round],
                repsController: _repsB[round],
                isCompleted: _completedB[round],
                targetReps: widget.targetReps,
                onComplete: () => _complete(false, round),
                accentColor: theme.colorScheme.secondary,
              ),
            ],
          ),
        );
      }),
    );
  }
}
