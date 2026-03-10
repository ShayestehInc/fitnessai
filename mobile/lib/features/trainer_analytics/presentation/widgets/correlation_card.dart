import 'package:flutter/material.dart';
import '../../data/models/analytics_models.dart';

class CorrelationCard extends StatelessWidget {
  final CorrelationPointModel correlation;

  const CorrelationCard({super.key, required this.correlation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rColor = _correlationColor(correlation.correlation);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_formatMetric(correlation.metricA)} vs ${_formatMetric(correlation.metricB)}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                _CorrelationBadge(
                  value: correlation.correlation,
                  color: rColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _CorrelationBar(
              value: correlation.correlation,
              color: rColor,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InterpretationBadge(
                  strength: correlation.strengthLabel,
                  isPositive: correlation.isPositive,
                ),
                const Spacer(),
                Text(
                  'n=${correlation.sampleSize}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            if (correlation.interpretation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                correlation.interpretation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMetric(String metric) {
    return metric.replaceAll('_', ' ').split(' ').map(
      (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
    ).join(' ');
  }

  Color _correlationColor(double r) {
    final abs = r.abs();
    if (abs >= 0.7) return r > 0 ? Colors.green : Colors.red;
    if (abs >= 0.4) return r > 0 ? Colors.lightGreen : Colors.orange;
    return Colors.grey;
  }
}

class _CorrelationBadge extends StatelessWidget {
  final double value;
  final Color color;

  const _CorrelationBadge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'r = ${value.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _CorrelationBar extends StatelessWidget {
  final double value;
  final Color color;

  const _CorrelationBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barWidth = (value.abs() / 1.0).clamp(0.0, 1.0);

    return SizedBox(
      height: 6,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: barWidth,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterpretationBadge extends StatelessWidget {
  final String strength;
  final bool isPositive;

  const _InterpretationBadge({
    required this.strength,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          '$strength ${isPositive ? "positive" : "negative"}',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
