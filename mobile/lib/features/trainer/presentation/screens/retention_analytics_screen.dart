import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/retention_model.dart';
import '../providers/trainer_provider.dart';
import '../widgets/retention_summary_card.dart';
import '../widgets/at_risk_trainee_tile.dart';

/// Full-screen retention analytics with period selector and trainee list.
class RetentionAnalyticsScreen extends ConsumerStatefulWidget {
  const RetentionAnalyticsScreen({super.key});

  @override
  ConsumerState<RetentionAnalyticsScreen> createState() =>
      _RetentionAnalyticsScreenState();
}

class _RetentionAnalyticsScreenState
    extends ConsumerState<RetentionAnalyticsScreen> {
  int _days = 14;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(retentionAnalyticsProvider(_days));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retention Analytics'),
        actions: [
          _PeriodChip(
            days: _days,
            onChanged: (d) => setState(() => _days = d),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(retentionAnalyticsProvider(_days));
        },
        child: analyticsAsync.when(
          data: (data) {
            if (data == null) {
              return _buildEmpty(context);
            }
            final analytics = RetentionAnalyticsModel.fromJson(data);
            if (analytics.summary.totalTrainees == 0) {
              return _buildEmpty(context);
            }
            return _buildContent(context, analytics);
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: $e', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 16),
              Text(
                'No Trainee Data',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Invite trainees to see retention analytics.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RetentionAnalyticsModel analytics) {
    final theme = Theme.of(context);
    final atRisk = analytics.trainees
        .where((t) => t.riskTier == 'critical' || t.riskTier == 'high')
        .toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RetentionSummaryCard(summary: analytics.summary),
          const SizedBox(height: 16),
          // At-risk section
          if (atRisk.isNotEmpty) ...[
            Text(
              'At-Risk Trainees (${atRisk.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: atRisk.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => AtRiskTraineeTile(
                trainee: atRisk[index],
                onTap: () => context.push(
                  '/trainer/trainees/${atRisk[index].traineeId}',
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // All trainees section
          Text(
            'All Trainees (${analytics.trainees.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: analytics.trainees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => AtRiskTraineeTile(
              trainee: analytics.trainees[index],
              onTap: () => context.push(
                '/trainer/trainees/${analytics.trainees[index].traineeId}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final int days;
  final ValueChanged<int> onChanged;

  const _PeriodChip({required this.days, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7d')),
        ButtonSegment(value: 14, label: Text('14d')),
        ButtonSegment(value: 30, label: Text('30d')),
      ],
      selected: {days},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
