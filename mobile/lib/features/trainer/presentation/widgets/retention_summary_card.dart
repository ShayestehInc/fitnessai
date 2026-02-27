import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/retention_model.dart';

/// Grid of 4 stat cards showing retention summary.
class RetentionSummaryCard extends StatelessWidget {
  final RetentionSummaryModel summary;

  const RetentionSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: [
        _StatTile(
          label: 'At-Risk',
          value: '${summary.atRiskCount}',
          subtitle: '${summary.criticalCount} critical, ${summary.highCount} high',
          valueColor: summary.atRiskCount > 0 ? const Color(0xFFF97316) : null,
          icon: Icons.warning_amber_rounded,
        ),
        _StatTile(
          label: 'Avg Engagement',
          value: '${summary.avgEngagement.toStringAsFixed(0)}%',
          subtitle: '14-day rolling',
          icon: Icons.favorite_rounded,
        ),
        _StatTile(
          label: 'Retention Rate',
          value: '${summary.retentionRate.toStringAsFixed(0)}%',
          subtitle: '${summary.totalTrainees - summary.atRiskCount}/${summary.totalTrainees} engaged',
          valueColor: summary.retentionRate >= 80 ? const Color(0xFF22C55E) : null,
          icon: Icons.group_rounded,
        ),
        _StatTile(
          label: 'Critical',
          value: '${summary.criticalCount}',
          subtitle: 'Needs attention',
          valueColor: summary.criticalCount > 0 ? const Color(0xFFEF4444) : null,
          icon: Icons.trending_down_rounded,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color? valueColor;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.subtitle,
    this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 14, color: AppTheme.mutedForeground),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: theme.textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
