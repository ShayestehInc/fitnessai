import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/lift_models.dart';
import '../providers/lift_provider.dart';

/// Weekly workload overview screen with total workload,
/// muscle group breakdown, daily breakdown, and ACWR indicator.
class WorkloadScreen extends ConsumerStatefulWidget {
  const WorkloadScreen({super.key});

  @override
  ConsumerState<WorkloadScreen> createState() => _WorkloadScreenState();
}

class _WorkloadScreenState extends ConsumerState<WorkloadScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(liftNotifierProvider.notifier);
      notifier.loadWeeklyWorkload();
      notifier.loadWorkloadTrends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(liftNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workload')),
      body: _buildBody(theme, state),
    );
  }

  Widget _buildBody(ThemeData theme, LiftState state) {
    if (state.isLoading &&
        state.weeklyWorkload == null &&
        state.workloadTrends == null) {
      return const Center(child: AdaptiveSpinner());
    }

    if (state.error != null &&
        state.weeklyWorkload == null &&
        state.workloadTrends == null) {
      return _buildErrorState(theme, state.error!);
    }

    return RefreshIndicator(
      onRefresh: () async {
        final notifier = ref.read(liftNotifierProvider.notifier);
        await Future.wait([
          notifier.loadWeeklyWorkload(),
          notifier.loadWorkloadTrends(),
        ]);
      },
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.workloadTrends != null)
            _AcwrCard(trends: state.workloadTrends!),
          if (state.weeklyWorkload != null) ...[
            const SizedBox(height: 16),
            _WeeklyOverviewCard(weekly: state.weeklyWorkload!),
            if (state.weeklyWorkload!.byMuscleGroup.isNotEmpty) ...[
              const SizedBox(height: 16),
              _MuscleGroupBreakdown(
                muscleGroups: state.weeklyWorkload!.byMuscleGroup,
                totalWorkload: state.weeklyWorkload!.totalWorkload,
              ),
            ],
            if (state.weeklyWorkload!.dailyBreakdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DailyBreakdownList(
                days: state.weeklyWorkload!.dailyBreakdown,
                totalWorkload: state.weeklyWorkload!.totalWorkload,
              ),
            ],
          ],
          if (state.weeklyWorkload == null && state.workloadTrends == null)
            _buildEmptyState(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart,
              color: AppTheme.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Workload Data',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some workouts and your workload analytics will appear here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.destructive,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Workload',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final notifier = ref.read(liftNotifierProvider.notifier);
                notifier.loadWeeklyWorkload();
                notifier.loadWorkloadTrends();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ACWR (Acute:Chronic Workload Ratio) indicator card.
class _AcwrCard extends StatelessWidget {
  final WorkloadTrendsModel trends;

  const _AcwrCard({required this.trends});

  Color get _acwrColor {
    if (trends.acuteChronicRatio < 0.8) return Colors.blue;
    if (trends.acuteChronicRatio <= 1.3) return Colors.green;
    if (trends.acuteChronicRatio <= 1.5) return Colors.orange;
    return AppTheme.destructive;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Acute:Chronic Ratio',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foreground,
                ),
              ),
              const Spacer(),
              if (trends.spikeFlag)
                _buildFlag(theme, 'SPIKE', AppTheme.destructive),
              if (trends.dipFlag)
                _buildFlag(theme, 'DIP', Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trends.acuteChronicRatio.toStringAsFixed(2),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _acwrColor,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _acwrColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trends.acwrLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _acwrColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRollingAverages(theme),
        ],
      ),
    );
  }

  Widget _buildFlag(ThemeData theme, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildRollingAverages(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildRollingTile(
            theme,
            label: '7-Day Avg',
            value: trends.rolling7Day,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRollingTile(
            theme,
            label: '28-Day Avg',
            value: trends.rolling28Day,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Icon(
                trends.trendDirection == 'up'
                    ? Icons.trending_up
                    : trends.trendDirection == 'down'
                        ? Icons.trending_down
                        : Icons.trending_flat,
                color: trends.trendDirection == 'up'
                    ? Colors.green
                    : trends.trendDirection == 'down'
                        ? AppTheme.destructive
                        : AppTheme.mutedForeground,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Trend',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRollingTile(
    ThemeData theme, {
    required String label,
    required double value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            _formatWorkload(value),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedForeground,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWorkload(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

/// Weekly overview card showing total workload and session count.
class _WeeklyOverviewCard extends StatelessWidget {
  final WorkloadWeeklyModel weekly;

  const _WeeklyOverviewCard({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Overview',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${weekly.weekStart} - ${weekly.weekEnd}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  theme,
                  label: 'Total Workload',
                  value: _formatWorkload(weekly.totalWorkload),
                ),
              ),
              Expanded(
                child: _buildStat(
                  theme,
                  label: 'Sessions',
                  value: '${weekly.sessionCount}',
                ),
              ),
              Expanded(
                child: _buildStat(
                  theme,
                  label: 'Avg / Session',
                  value:
                      _formatWorkload(weekly.averageWorkloadPerSession),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatWorkload(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

/// Muscle group breakdown with horizontal bar chart.
class _MuscleGroupBreakdown extends StatelessWidget {
  final Map<String, double> muscleGroups;
  final double totalWorkload;

  const _MuscleGroupBreakdown({
    required this.muscleGroups,
    required this.totalWorkload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = muscleGroups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By Muscle Group',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((entry) => _buildRow(theme, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildRow(ThemeData theme, String name, double value) {
    final fraction = totalWorkload > 0 ? value / totalWorkload : 0.0;
    final percentage = (fraction * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.foreground,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppTheme.zinc700,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Daily breakdown list showing each day's workload.
class _DailyBreakdownList extends StatelessWidget {
  final List<DailyBreakdownModel> days;
  final double totalWorkload;

  const _DailyBreakdownList({
    required this.days,
    required this.totalWorkload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Breakdown',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 12),
          ...days.map((day) => _buildDayRow(theme, day)),
        ],
      ),
    );
  }

  Widget _buildDayRow(ThemeData theme, DailyBreakdownModel day) {
    final fraction = totalWorkload > 0 ? day.workload / totalWorkload : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day.date.length >= 10
                  ? day.date.substring(5)
                  : day.date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: AppTheme.zinc700,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              _formatWorkload(day.workload),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.foreground,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWorkload(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
