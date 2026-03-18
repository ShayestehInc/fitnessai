import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single SET row with weight, reps, and completion checkbox.
/// Extracted from ClassicWorkoutLayout for reuse across all modality widgets.
class SetInputRow extends StatelessWidget {
  final int setNumber;
  final String setLabel; // "1", "D1" for drop, "A" for activation, etc.
  final String setType; // working, drop, activation, mini, cluster, back_off, top
  final TextEditingController weightController;
  final TextEditingController repsController;
  final bool isCompleted;
  final double? targetWeight;
  final int? targetReps;
  final String? tempoDisplay;
  final VoidCallback onComplete;
  final Color? accentColor;

  const SetInputRow({
    super.key,
    required this.setNumber,
    required this.setLabel,
    this.setType = 'working',
    required this.weightController,
    required this.repsController,
    required this.isCompleted,
    this.targetWeight,
    this.targetReps,
    this.tempoDisplay,
    required this.onComplete,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? _colorForSetType(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? color.withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border(
          left: BorderSide(width: 3, color: color.withValues(alpha: isCompleted ? 0.6 : 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Set label
          SizedBox(
            width: 32,
            child: Text(
              setLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Weight input
          Expanded(
            flex: 3,
            child: _NumberInput(
              controller: weightController,
              hint: targetWeight != null ? '${targetWeight!.toStringAsFixed(0)}' : 'lbs',
              enabled: !isCompleted,
              decimal: true,
            ),
          ),
          const SizedBox(width: 8),
          // Reps input
          Expanded(
            flex: 2,
            child: _NumberInput(
              controller: repsController,
              hint: targetReps?.toString() ?? 'reps',
              enabled: !isCompleted,
            ),
          ),
          const SizedBox(width: 8),
          // Tempo badge (when applicable)
          if (tempoDisplay != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tempoDisplay!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Complete checkbox
          GestureDetector(
            onTap: isCompleted ? null : onComplete,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? color : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? color : theme.dividerColor,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForSetType(ThemeData theme) {
    switch (setType) {
      case 'top':
        return theme.colorScheme.error;
      case 'drop':
        return Colors.orange;
      case 'activation':
        return theme.colorScheme.primary;
      case 'mini':
        return theme.colorScheme.tertiary;
      case 'cluster':
        return Colors.purple;
      case 'back_off':
        return Colors.teal;
      default:
        return theme.colorScheme.primary;
    }
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool decimal;

  const _NumberInput({
    required this.controller,
    required this.hint,
    this.enabled = true,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[\d.]') : RegExp(r'\d'),
        ),
      ],
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: enabled ? null : theme.textTheme.bodySmall?.color,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
    );
  }
}
