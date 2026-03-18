import 'package:flutter/material.dart';

import 'shared/micro_rest_timer.dart';
import 'shared/set_input_row.dart';

/// Myo-rep logging — activation set then mini-sets with micro-rests.
class MyoRepLog extends StatefulWidget {
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;

  const MyoRepLog({
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
  State<MyoRepLog> createState() => _MyoRepLogState();
}

class _MyoRepLogState extends State<MyoRepLog> {
  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _repsControllers = [];
  final List<bool> _completed = [];
  bool _showingRest = false;

  int get _miniRestSeconds => widget.modalityDetails?['mini_rest'] as int? ?? 5;
  int get _activationReps => widget.modalityDetails?['activation_reps'] as int? ?? widget.targetReps;

  @override
  void initState() {
    super.initState();
    _addRow(); // Activation set
  }

  void _addRow() {
    _weightControllers.add(TextEditingController());
    _repsControllers.add(TextEditingController());
    _completed.add(false);
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
    final reps = int.tryParse(_repsControllers[index].text) ?? _activationReps;
    final isActivation = index == 0;
    setState(() {
      _completed[index] = true;
      if (!isActivation && reps < 5) return; // Auto-stop threshold
      _showingRest = true;
    });
    widget.onSetCompleted(
      index,
      weight,
      reps,
      isActivation ? 'activation' : 'mini',
    );
  }

  void _onRestComplete() {
    setState(() {
      _showingRest = false;
      _addRow();
    });
  }

  bool get _autoStopped {
    if (_completed.length < 2 || !_completed.last) return false;
    final lastReps = int.tryParse(_repsControllers.last.text) ?? 0;
    return lastReps < 5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _completed.length; i++) ...[
          SetInputRow(
            setNumber: i + 1,
            setLabel: i == 0 ? 'ACT' : 'M${i}',
            setType: i == 0 ? 'activation' : 'mini',
            weightController: _weightControllers[i],
            repsController: _repsControllers[i],
            isCompleted: _completed[i],
            targetWeight: widget.lastWeight,
            targetReps: i == 0 ? _activationReps : (widget.targetReps ~/ 3).clamp(3, 8),
            onComplete: () => _onComplete(i),
            accentColor: i == 0 ? theme.colorScheme.primary : theme.colorScheme.tertiary,
          ),
          const SizedBox(height: 2),
        ],
        if (_showingRest)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: MicroRestTimer(
              durationSeconds: _miniRestSeconds,
              onComplete: _onRestComplete,
              color: theme.colorScheme.tertiary,
            ),
          ),
        if (_autoStopped)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Auto-stopped: reps dropped below threshold',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
