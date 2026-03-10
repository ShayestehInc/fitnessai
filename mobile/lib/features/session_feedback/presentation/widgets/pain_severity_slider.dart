import 'package:flutter/material.dart';

/// Visual pain scale slider (1-10) with a color gradient from green to red.
class PainSeveritySlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const PainSeveritySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _severityColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pain Score',
              style: theme.textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$value/10 — ${_severityLabel(value)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: theme.dividerColor,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'No pain',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Worst pain',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  static Color _severityColor(int score) {
    if (score <= 3) return const Color(0xFF22C55E);
    if (score <= 5) return const Color(0xFFF59E0B);
    if (score <= 7) return const Color(0xFFEF4444);
    return const Color(0xFF991B1B);
  }

  static String _severityLabel(int score) {
    if (score <= 2) return 'Mild';
    if (score <= 4) return 'Moderate';
    if (score <= 6) return 'Significant';
    if (score <= 8) return 'Severe';
    return 'Extreme';
  }
}
