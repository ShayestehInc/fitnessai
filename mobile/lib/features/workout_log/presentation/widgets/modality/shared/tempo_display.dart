import 'package:flutter/material.dart';

/// Prominent tempo badge for controlled eccentrics and any exercise with tempo.
/// Shows E-P-C-P format with labels.
class TempoDisplay extends StatelessWidget {
  final String tempo; // e.g. "4-1-1-1"
  final bool compact;

  const TempoDisplay({
    super.key,
    required this.tempo,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = tempo.split('-');
    if (parts.length != 4) {
      return Text(tempo, style: TextStyle(color: theme.colorScheme.secondary));
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          tempo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.secondary,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TempoPhase(label: 'ECC', value: parts[0], color: theme.colorScheme.error),
          _TempoDivider(theme: theme),
          _TempoPhase(label: 'PAU', value: parts[1], color: theme.colorScheme.tertiary),
          _TempoDivider(theme: theme),
          _TempoPhase(label: 'CON', value: parts[2], color: theme.colorScheme.primary),
          _TempoDivider(theme: theme),
          _TempoPhase(label: 'PAU', value: parts[3], color: theme.colorScheme.tertiary),
        ],
      ),
    );
  }
}

class _TempoPhase extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TempoPhase({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value == 'X' ? 'X' : '${value}s',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _TempoDivider extends StatelessWidget {
  final ThemeData theme;
  const _TempoDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '-',
        style: TextStyle(
          fontSize: 16,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}
