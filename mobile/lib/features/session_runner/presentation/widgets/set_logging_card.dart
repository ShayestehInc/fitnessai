import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/session_models.dart';

/// Per-set input card with fields for reps, load, RPE, plus Log/Skip buttons.
/// Displays visual status indicator and prescribed values for reference.
class SetLoggingCard extends StatefulWidget {
  final SessionSetModel set;
  final String loadUnit;
  final bool isLogging;
  final void Function({
    required int completedReps,
    required double loadValue,
    required String loadUnit,
    double? rpe,
    String? notes,
  }) onLogSet;
  final void Function({String? reason}) onSkipSet;

  const SetLoggingCard({
    super.key,
    required this.set,
    required this.loadUnit,
    required this.isLogging,
    required this.onLogSet,
    required this.onSkipSet,
  });

  @override
  State<SetLoggingCard> createState() => _SetLoggingCardState();
}

class _SetLoggingCardState extends State<SetLoggingCard> {
  late final TextEditingController _repsController;
  late final TextEditingController _loadController;
  late final TextEditingController _notesController;
  double _rpe = 0;

  @override
  void initState() {
    super.initState();
    final prescribedReps = widget.set.prescribedRepsMin ?? 0;
    _repsController = TextEditingController(
      text: prescribedReps > 0 ? prescribedReps.toString() : '',
    );

    final prescribedLoad = widget.set.prescribedLoad;
    _loadController = TextEditingController(
      text: prescribedLoad ?? '',
    );

    _notesController = TextEditingController();
  }

  @override
  void didUpdateWidget(SetLoggingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.setLogId != widget.set.setLogId) {
      final prescribedReps = widget.set.prescribedRepsMin ?? 0;
      _repsController.text =
          prescribedReps > 0 ? prescribedReps.toString() : '';
      _loadController.text = widget.set.prescribedLoad ?? '';
      _notesController.clear();
      _rpe = 0;
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _loadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final setModel = widget.set;

    if (setModel.isCompleted) {
      return _CompletedSetView(set: setModel);
    }

    if (setModel.isSkipped) {
      return _SkippedSetView(set: setModel);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SetHeader(setNumber: setModel.setNumber, status: 'pending'),
            const SizedBox(height: 12),
            _PrescribedInfo(set: setModel),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: InputDecoration(
                      labelText: 'Reps',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'reps',
                      suffixStyle: theme.textTheme.bodySmall,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _loadController,
                    decoration: InputDecoration(
                      labelText: 'Load',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixText: widget.loadUnit,
                      suffixStyle: theme.textTheme.bodySmall,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RpeSlider(
              value: _rpe,
              onChanged: (v) => setState(() => _rpe = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: widget.isLogging ? null : _handleLogSet,
                    child: widget.isLogging
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Log Set'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: widget.isLogging ? null : _handleSkipSet,
                  child: const Text('Skip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogSet() {
    final reps = int.tryParse(_repsController.text.trim());
    final load = double.tryParse(_loadController.text.trim());

    if (reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number of reps')),
      );
      return;
    }

    if (load == null || load < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid load value')),
      );
      return;
    }

    widget.onLogSet(
      completedReps: reps,
      loadValue: load,
      loadUnit: widget.loadUnit,
      rpe: _rpe > 0 ? _rpe : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );
  }

  void _handleSkipSet() {
    showDialog<String>(
      context: context,
      builder: (ctx) => _SkipReasonDialog(),
    ).then((reason) {
      if (reason != null) {
        widget.onSkipSet(reason: reason.isNotEmpty ? reason : null);
      }
    });
  }
}

class _SetHeader extends StatelessWidget {
  final int setNumber;
  final String status;

  const _SetHeader({required this.setNumber, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      case 'skipped':
        statusColor = Colors.orange;
        statusIcon = Icons.skip_next;
      default:
        statusColor = colorScheme.primary;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 20, color: statusColor),
        const SizedBox(width: 8),
        Text(
          'Set $setNumber',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PrescribedInfo extends StatelessWidget {
  final SessionSetModel set;

  const _PrescribedInfo({required this.set});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            'Target: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '${set.prescribedRepsDisplay} reps',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '@ ${set.prescribedLoadDisplay}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (set.restPrescribedSeconds != null &&
              set.restPrescribedSeconds! > 0) ...[
            const Spacer(),
            Icon(Icons.timer, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '${set.restPrescribedSeconds}s rest',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RpeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _RpeSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RPE',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value > 0 ? value.toStringAsFixed(1) : '-',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 10,
          divisions: 20,
          label: value > 0 ? value.toStringAsFixed(1) : 'None',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CompletedSetView extends StatelessWidget {
  final SessionSetModel set;

  const _CompletedSetView({required this.set});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.green.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Set ${set.setNumber}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${set.completedReps ?? '-'} reps',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: 12),
            Text(
              '${set.completedLoadValue ?? '-'} ${set.completedLoadUnit ?? ''}',
              style: theme.textTheme.bodyMedium,
            ),
            if (set.rpe != null) ...[
              const SizedBox(width: 12),
              Text(
                'RPE ${set.rpe!.toStringAsFixed(1)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkippedSetView extends StatelessWidget {
  final SessionSetModel set;

  const _SkippedSetView({required this.set});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.orange.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.skip_next, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'Set ${set.setNumber}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              'Skipped',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkipReasonDialog extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  _SkipReasonDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Skip Set'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Are you sure you want to skip this set?'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}
