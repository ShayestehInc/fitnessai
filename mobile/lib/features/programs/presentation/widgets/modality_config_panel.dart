import 'package:flutter/material.dart';

/// Configuration panel for per-modality settings.
/// Shows relevant controls based on the selected set structure.
class ModalityConfigPanel extends StatelessWidget {
  final String setStructure;
  final Map<String, dynamic> details;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const ModalityConfigPanel({
    super.key,
    required this.setStructure,
    required this.details,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (setStructure) {
      case 'drop_sets':
        return _DropSetConfig(details: details, onChanged: onChanged);
      case 'myo_reps':
        return _MyoRepConfig(details: details, onChanged: onChanged);
      case 'rest_pause':
        return _RestPauseConfig(details: details, onChanged: onChanged);
      case 'cluster_sets':
        return _ClusterConfig(details: details, onChanged: onChanged);
      case 'pyramid_ascending':
      case 'pyramid_descending':
        return _PyramidConfig(details: details, onChanged: onChanged);
      case 'down_sets':
        return _DownSetConfig(details: details, onChanged: onChanged);
      case 'controlled_eccentrics':
        return _TempoConfig(details: details, onChanged: onChanged);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DropSetConfig extends StatelessWidget {
  final Map<String, dynamic> details;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _DropSetConfig({required this.details, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dropCount = (details['drop_count'] as int?) ?? 3;
    final dropPercent = (details['drop_percent'] as num?)?.toDouble() ?? 20.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SliderRow(
          label: 'Number of drops',
          value: dropCount.toDouble(),
          min: 1, max: 5, divisions: 4,
          display: '$dropCount',
          onChanged: (v) => onChanged({...details, 'drop_count': v.round()}),
        ),
        _SliderRow(
          label: 'Weight reduction per drop',
          value: dropPercent,
          min: 10, max: 40, divisions: 6,
          display: '${dropPercent.round()}%',
          onChanged: (v) => onChanged({...details, 'drop_percent': v}),
        ),
      ],
    );
  }
}

class _MyoRepConfig extends StatelessWidget {
  final Map<String, dynamic> details;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _MyoRepConfig({required this.details, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final activationReps = (details['activation_reps'] as int?) ?? 15;
    final miniSetReps = (details['mini_set_reps'] as int?) ?? 5;
    final maxMiniSets = (details['max_mini_sets'] as int?) ?? 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SliderRow(label: 'Activation reps', value: activationReps.toDouble(), min: 10, max: 25, divisions: 15, display: '$activationReps', onChanged: (v) => onChanged({...details, 'activation_reps': v.round()})),
        _SliderRow(label: 'Mini-set reps', value: miniSetReps.toDouble(), min: 3, max: 8, divisions: 5, display: '$miniSetReps', onChanged: (v) => onChanged({...details, 'mini_set_reps': v.round()})),
        _SliderRow(label: 'Max mini-sets', value: maxMiniSets.toDouble(), min: 2, max: 6, divisions: 4, display: '$maxMiniSets', onChanged: (v) => onChanged({...details, 'max_mini_sets': v.round()})),
      ],
    );
  }
}

class _RestPauseConfig extends StatelessWidget {
  final Map<String, dynamic> details;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _RestPauseConfig({required this.details, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pauseCount = (details['pause_count'] as int?) ?? 2;
    final microRest = (details['micro_rest_seconds'] as int?) ?? 15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SliderRow(label: 'Number of pauses', value: pauseCount.toDouble(), min: 1, max: 4, divisions: 3, display: '$pauseCount', onChanged: (v) => onChanged({...details, 'pause_count': v.round()})),
        _SliderRow(label: 'Rest between pauses', value: microRest.toDouble(), min: 5, max: 20, divisions: 3, display: '${microRest}s', onChanged: (v) => onChanged({...details, 'micro_rest_seconds': v.round()})),
      ],
    );
  }
}

class _ClusterConfig extends StatelessWidget {
  final Map<String, dynamic> details;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _ClusterConfig({required this.details, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final repsPerCluster = (details['reps_per_cluster'] as int?) ?? 2;
    final intraRest = (details['intra_rest_seconds'] as int?) ?? 15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SliderRow(label: 'Reps per cluster', value: repsPerCluster.toDouble(), min: 1, max: 5, divisions: 4, display: '$repsPerCluster', onChanged: (v) => onChanged({...details, 'reps_per_cluster': v.round()})),
        _SliderRow(label: 'Intra-cluster rest', value: intraRest.toDouble(), min: 5, max: 30, divisions: 5, display: '${intraRest}s', onChanged: (v) => onChanged({...details, 'intra_rest_seconds': v.round()})),
      ],
    );
  }
}

class _PyramidConfig extends StatelessWidget {
  final Map<String, dynamic> details;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _PyramidConfig({required this.details, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final stepPercent = (details['step_percent'] as num?)?.toDouble() ?? 5.0;
    return _SliderRow(label: 'Weight step per set', value: stepPercent, min: 2.5, max: 15, divisions: 5, display: '${stepPercent.round()}%', onChanged: (v) => onChanged({...details, 'step_percent': v}));
  }
}

class _DownSetConfig extends StatelessWidget {
  final Map<String, dynamic> details;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _DownSetConfig({required this.details, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final topSetCount = (details['top_set_count'] as int?) ?? 2;
    final backOffPercent = (details['back_off_percent'] as num?)?.toDouble() ?? 15.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SliderRow(label: 'Top sets', value: topSetCount.toDouble(), min: 1, max: 3, divisions: 2, display: '$topSetCount', onChanged: (v) => onChanged({...details, 'top_set_count': v.round()})),
        _SliderRow(label: 'Back-off reduction', value: backOffPercent, min: 10, max: 30, divisions: 4, display: '${backOffPercent.round()}%', onChanged: (v) => onChanged({...details, 'back_off_percent': v})),
      ],
    );
  }
}

class _TempoConfig extends StatelessWidget {
  final Map<String, dynamic> details;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _TempoConfig({required this.details, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tempo = (details['tempo'] as String?) ?? '4-1-1-1';
    final presets = {
      '4-1-1-1': 'Hypertrophy (lengthened bias)',
      '3-3-1-0': 'Joint-friendly control',
      '5-0-2-0': 'Slow eccentric',
      '3-2-1-0': 'Technique focus',
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: presets.entries.map((e) {
        final isSelected = tempo == e.key;
        return GestureDetector(
          onTap: () => onChanged({...details, 'tempo': e.key}),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.key, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isSelected ? theme.colorScheme.primary : null)),
                Text(e.value, style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            flex: 4,
            child: Slider.adaptive(
              value: value.clamp(min, max),
              min: min, max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(display, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
