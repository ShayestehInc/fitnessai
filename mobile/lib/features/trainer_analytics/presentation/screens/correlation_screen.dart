import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_models.dart';
import '../providers/analytics_provider.dart';
import '../widgets/correlation_card.dart';
import '../widgets/insight_card.dart';

class CorrelationScreen extends ConsumerStatefulWidget {
  const CorrelationScreen({super.key});

  @override
  ConsumerState<CorrelationScreen> createState() => _CorrelationScreenState();
}

class _CorrelationScreenState extends ConsumerState<CorrelationScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(correlationsProvider(_days));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Correlations & Insights'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today, size: 20),
            onSelected: (days) => setState(() => _days = days),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 14, child: Text('Last 14 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
              PopupMenuItem(value: 60, child: Text('Last 60 days')),
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(correlationsProvider(_days)),
        child: dataAsync.when(
          data: (overview) => _buildContent(theme, overview),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorState(theme, e.toString()),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, CorrelationOverviewModel overview) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeriodHeader(theme),
        const SizedBox(height: 16),
        if (overview.correlations.isNotEmpty) ...[
          Text('Metric Correlations', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...overview.correlations.map(
            (c) => CorrelationCard(correlation: c),
          ),
          const SizedBox(height: 24),
        ],
        if (overview.insights.isNotEmpty) ...[
          Text('Trainee Insights', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...overview.insights.map(
            (i) => InsightCard(insight: i),
          ),
          const SizedBox(height: 24),
        ],
        if (overview.cohortComparisons.isNotEmpty) ...[
          Text('Cohort Comparisons', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...overview.cohortComparisons.map(
            (c) => _CohortCard(comparison: c),
          ),
        ],
        if (_isAllEmpty(overview)) _buildEmptyState(theme),
      ],
    );
  }

  bool _isAllEmpty(CorrelationOverviewModel overview) {
    return overview.correlations.isEmpty &&
        overview.insights.isEmpty &&
        overview.cohortComparisons.isEmpty;
  }

  Widget _buildPeriodHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Showing last $_days days',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('No analytics data yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Data will appear as your trainees log more activity',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load analytics', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(correlationsProvider(_days)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CohortCard extends StatelessWidget {
  final CohortComparisonModel comparison;

  const _CohortCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositiveDiff = comparison.differencePct > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatMetric(comparison.metric),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CohortColumn(
                    label: 'High Adherence',
                    value: comparison.highAdherenceAvg.toStringAsFixed(1),
                    count: comparison.highCount,
                    color: Colors.green,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isPositiveDiff ? Colors.green : Colors.red)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isPositiveDiff ? '+' : ''}${comparison.differencePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isPositiveDiff ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                Expanded(
                  child: _CohortColumn(
                    label: 'Low Adherence',
                    value: comparison.lowAdherenceAvg.toStringAsFixed(1),
                    count: comparison.lowCount,
                    color: Colors.orange,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
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
}

class _CohortColumn extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  final Color color;
  final bool alignEnd;

  const _CohortColumn({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(color: color),
        ),
        Text(
          '$count trainees',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}
