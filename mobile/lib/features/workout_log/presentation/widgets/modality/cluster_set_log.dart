import 'package:flutter/material.dart';

import 'shared/micro_rest_timer.dart';
import 'shared/set_input_row.dart';

/// Cluster sets: groups of 1-3 reps with micro-rests (10-20s) between clusters.
/// Each cluster gets its own check button. Labels: "Set 1 - Cluster 1", etc.
class ClusterSetLog extends StatefulWidget {
  final void Function(int setIndex, double weight, int reps, String setType)
      onSetCompleted;
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final double? lastWeight;
  final String? tempo;
  final Map<String, dynamic>? modalityDetails;

  const ClusterSetLog({
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
  State<ClusterSetLog> createState() => _ClusterSetLogState();
}

class _ClusterSetLogState extends State<ClusterSetLog> {
  late final int _clustersPerSet;
  late final int _clusterRest;
  late final int _repsPerCluster;
  late final int _totalClusters;
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;
  late final List<bool> _completed;
  int? _restingAfterCluster;

  @override
  void initState() {
    super.initState();
    _clustersPerSet =
        (widget.modalityDetails?['clusters_per_set'] as int?) ?? 3;
    _clusterRest =
        (widget.modalityDetails?['cluster_rest'] as int?) ?? 15;
    _repsPerCluster =
        (widget.modalityDetails?['reps_per_cluster'] as int?) ?? 2;
    _totalClusters = widget.totalSets * _clustersPerSet;
    _weightControllers = List.generate(
      _totalClusters, (_) => TextEditingController(),
    );
    _repsControllers = List.generate(
      _totalClusters, (_) => TextEditingController(),
    );
    _completed = List.filled(_totalClusters, false);
  }

  @override
  void dispose() {
    for (final c in _weightControllers) { c.dispose(); }
    for (final c in _repsControllers) { c.dispose(); }
    super.dispose();
  }

  void _onClusterComplete(int flatIndex, int setIndex) {
    final weight =
        double.tryParse(_weightControllers[flatIndex].text) ?? widget.lastWeight ?? 0;
    final reps =
        int.tryParse(_repsControllers[flatIndex].text) ?? _repsPerCluster;
    setState(() {
      _completed[flatIndex] = true;
      _restingAfterCluster = flatIndex;
    });
    widget.onSetCompleted(setIndex, weight, reps, 'cluster');
  }

  void _onMicroRestDone() {
    setState(() => _restingAfterCluster = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int s = 0; s < widget.totalSets; s++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: EdgeInsets.only(bottom: 4, top: s > 0 ? 10 : 0),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Set ${s + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          for (int c = 0; c < _clustersPerSet; c++) ...[
            _buildClusterRow(s, c),
            if (_restingAfterCluster == (s * _clustersPerSet + c) &&
                c < _clustersPerSet - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: MicroRestTimer(
                  durationSeconds: _clusterRest,
                  onComplete: _onMicroRestDone,
                  color: Colors.deepPurple,
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildClusterRow(int setIdx, int clusterIdx) {
    final flat = setIdx * _clustersPerSet + clusterIdx;
    return SetInputRow(
      setNumber: flat + 1,
      setLabel: 'C${clusterIdx + 1}',
      setType: 'cluster',
      weightController: _weightControllers[flat],
      repsController: _repsControllers[flat],
      isCompleted: _completed[flat],
      targetWeight: widget.lastWeight,
      targetReps: _repsPerCluster,
      tempoDisplay: widget.tempo,
      onComplete: () => _onClusterComplete(flat, setIdx),
    );
  }
}
