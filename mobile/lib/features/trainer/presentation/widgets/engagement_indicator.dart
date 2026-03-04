import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_progress_bar.dart';

/// Horizontal progress bar with color gradient based on engagement value.
class EngagementIndicator extends StatelessWidget {
  final double value;
  final double width;

  const EngagementIndicator({
    super.key,
    required this.value,
    this.width = 60,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 100.0);
    final color = _getColor(clamped);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: 6,
          child: AdaptiveProgressBar(
              value: clamped / 100.0,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              color: color,
            ),
        ),
        const SizedBox(width: 6),
        Text(
          '${clamped.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  static Color _getColor(double value) {
    if (value >= 75) return const Color(0xFF22C55E);
    if (value >= 50) return const Color(0xFFEAB308);
    if (value >= 25) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }
}
