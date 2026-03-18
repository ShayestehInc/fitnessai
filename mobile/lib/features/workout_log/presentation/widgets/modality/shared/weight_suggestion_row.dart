import 'package:flutter/material.dart';

/// Shows auto-calculated weight target for drops, pyramids, down sets.
class WeightSuggestionRow extends StatelessWidget {
  final double baseWeight;
  final double multiplier;
  final String label; // e.g. "Drop 1 (-20%)", "Back-off (-15%)"

  const WeightSuggestionRow({
    super.key,
    required this.baseWeight,
    required this.multiplier,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestedWeight = _roundToNearest(baseWeight * multiplier, 2.5);
    final percentChange = ((multiplier - 1) * 100).round();
    final percentLabel = percentChange >= 0 ? '+$percentChange%' : '$percentChange%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            multiplier >= 1 ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: multiplier >= 1 ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          Text(
            '~${suggestedWeight.toStringAsFixed(suggestedWeight % 1 == 0 ? 0 : 1)} lbs',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: (multiplier >= 1 ? Colors.green : Colors.orange).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              percentLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: multiplier >= 1 ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _roundToNearest(double value, double increment) {
    return (value / increment).round() * increment;
  }
}
