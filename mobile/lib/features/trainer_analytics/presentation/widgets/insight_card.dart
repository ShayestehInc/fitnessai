import 'package:flutter/material.dart';
import '../../data/models/analytics_models.dart';

class InsightCard extends StatelessWidget {
  final TraineeInsightModel insight;
  final VoidCallback? onTap;

  const InsightCard({super.key, required this.insight, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityConfig = _severityConfig(insight.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityConfig.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  severityConfig.icon,
                  size: 20,
                  color: severityConfig.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            insight.traineeName,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        _InsightTypeBadge(type: insight.insightType),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    if (insight.data.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: insight.data.entries.take(3).map((entry) {
                          return _DataChip(label: entry.key, value: '${entry.value}');
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _SeverityConfig _severityConfig(String severity) {
    switch (severity) {
      case 'warning':
      case 'high':
        return const _SeverityConfig(
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
        );
      case 'critical':
        return const _SeverityConfig(
          icon: Icons.error_outline,
          color: Colors.red,
        );
      case 'success':
      case 'positive':
        return const _SeverityConfig(
          icon: Icons.check_circle_outline,
          color: Colors.green,
        );
      default:
        return const _SeverityConfig(
          icon: Icons.info_outline,
          color: Colors.blue,
        );
    }
  }
}

class _SeverityConfig {
  final IconData icon;
  final Color color;

  const _SeverityConfig({required this.icon, required this.color});
}

class _InsightTypeBadge extends StatelessWidget {
  final String type;

  const _InsightTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.replaceAll('_', ' '),
        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  final String label;
  final String value;

  const _DataChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${label.replaceAll('_', ' ')}: $value',
        style: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
