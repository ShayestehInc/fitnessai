import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_models.dart';
import '../providers/analytics_provider.dart';
import '../widgets/insight_card.dart';

class TraineePatternsScreen extends ConsumerStatefulWidget {
  final int traineeId;
  final String traineeName;

  const TraineePatternsScreen({
    super.key,
    required this.traineeId,
    required this.traineeName,
  });

  @override
  ConsumerState<TraineePatternsScreen> createState() =>
      _TraineePatternsScreenState();
}

class _TraineePatternsScreenState extends ConsumerState<TraineePatternsScreen> {
  int _days = 30;

  TraineePatternParams get _params =>
      TraineePatternParams(traineeId: widget.traineeId, days: _days);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(traineePatternsProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.traineeName),
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
        onRefresh: () async => ref.invalidate(traineePatternsProvider(_params)),
        child: dataAsync.when(
          data: (patterns) => _buildContent(theme, patterns),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorState(theme, e.toString()),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, TraineePatternsModel patterns) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAdherenceSection(theme, patterns.adherenceStats),
        const SizedBox(height: 24),
        if (patterns.insights.isNotEmpty) ...[
          Text('Insights', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...patterns.insights.map((i) => InsightCard(insight: i)),
          const SizedBox(height: 24),
        ],
        if (patterns.exerciseProgressions.isNotEmpty) ...[
          Text('Exercise Progressions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...patterns.exerciseProgressions.map(
            (p) => _ExerciseProgressionCard(progression: p),
          ),
        ],
        if (patterns.insights.isEmpty &&
            patterns.exerciseProgressions.isEmpty)
          _buildEmptyInsightsState(theme),
      ],
    );
  }

  Widget _buildAdherenceSection(ThemeData theme, AdherenceStatsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Adherence', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AdherenceTile(
                label: 'Workouts',
                value: stats.workoutLoggingPct,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdherenceTile(
                label: 'Food Logging',
                value: stats.foodLoggingPct,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AdherenceTile(
                label: 'Protein',
                value: stats.proteinAdherencePct,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdherenceTile(
                label: 'Calories',
                value: stats.calorieAdherencePct,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyInsightsState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Not enough data for insights',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
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
          Text('Failed to load patterns', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(traineePatternsProvider(_params)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _AdherenceTile extends StatelessWidget {
  final String label;
  final double value;

  const _AdherenceTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForValue(value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (value / 100).clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                color: color,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForValue(double v) {
    if (v >= 80) return Colors.green;
    if (v >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _ExerciseProgressionCard extends StatelessWidget {
  final ExerciseProgressionModel progression;

  const _ExerciseProgressionCard({required this.progression});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendIcon = progression.isProgressing
        ? Icons.trending_up
        : progression.isRegressing
            ? Icons.trending_down
            : Icons.trending_flat;
    final trendColor = progression.isProgressing
        ? Colors.green
        : progression.isRegressing
            ? Colors.red
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(trendIcon, color: trendColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progression.exerciseName,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${progression.sessionsCount} sessions',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${progression.e1rmCurrent.toStringAsFixed(1)} lbs',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${progression.changePct >= 0 ? '+' : ''}${progression.changePct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
