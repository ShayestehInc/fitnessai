import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/lift_models.dart';
import '../providers/lift_provider.dart';
import '../widgets/e1rm_chart_widget.dart';

/// Displays e1RM and Training Max for all exercises.
/// Tapping an exercise shows its history chart in a bottom sheet.
class LiftMaxScreen extends ConsumerStatefulWidget {
  const LiftMaxScreen({super.key});

  @override
  ConsumerState<LiftMaxScreen> createState() => _LiftMaxScreenState();
}

class _LiftMaxScreenState extends ConsumerState<LiftMaxScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(liftNotifierProvider.notifier).loadLiftMaxes(),
    );
  }

  void _showExerciseHistory(LiftMaxModel liftMax) {
    ref
        .read(liftNotifierProvider.notifier)
        .loadExerciseHistory(liftMax.exercise);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ExerciseHistorySheet(
        exerciseName: liftMax.exerciseName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(liftNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Strength Maxes')),
      body: _buildBody(theme, state),
    );
  }

  Widget _buildBody(ThemeData theme, LiftState state) {
    if (state.isLoading && state.liftMaxes.isEmpty) {
      return const Center(child: AdaptiveSpinner());
    }

    if (state.error != null && state.liftMaxes.isEmpty) {
      return _buildErrorState(theme, state.error!);
    }

    if (state.liftMaxes.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(liftNotifierProvider.notifier).loadLiftMaxes();
      },
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.liftMaxes.length,
        itemBuilder: (context, index) {
          return _LiftMaxCard(
            liftMax: state.liftMaxes[index],
            onTap: () => _showExerciseHistory(state.liftMaxes[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.trending_up,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Strength Data',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete qualifying sets and your estimated 1RM and '
              'Training Max will be calculated automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedForeground,
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
              'Failed to Load Maxes',
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
              onPressed: () =>
                  ref.read(liftNotifierProvider.notifier).loadLiftMaxes(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying a single exercise's e1RM and TM.
class _LiftMaxCard extends StatelessWidget {
  final LiftMaxModel liftMax;
  final VoidCallback onTap;

  const _LiftMaxCard({required this.liftMax, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        liftMax.exerciseName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.mutedForeground,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (liftMax.hasE1rmData)
                      Expanded(
                        child: _buildValueColumn(
                          theme,
                          label: 'e1RM',
                          value:
                              '${liftMax.e1rmCurrent!.toStringAsFixed(1)} lbs',
                        ),
                      ),
                    if (liftMax.hasTmData) ...[
                      if (liftMax.hasE1rmData)
                        Container(
                          width: 1,
                          height: 32,
                          color: AppTheme.border,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      Expanded(
                        child: _buildValueColumn(
                          theme,
                          label: 'Training Max'
                              '${liftMax.tmPercentage != null ? ' (${(liftMax.tmPercentage! * 100).toStringAsFixed(0)}%)' : ''}',
                          value:
                              '${liftMax.tmCurrent!.toStringAsFixed(1)} lbs',
                        ),
                      ),
                    ],
                    if (!liftMax.hasE1rmData && !liftMax.hasTmData)
                      Text(
                        'No data yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueColumn(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet displaying e1RM and TM history charts.
class _ExerciseHistorySheet extends ConsumerWidget {
  final String exerciseName;

  const _ExerciseHistorySheet({required this.exerciseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(liftNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.zinc600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                exerciseName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: AdaptiveSpinner(),
                  ),
                )
              else if (state.error != null)
                _buildSheetError(theme, state.error!)
              else
                _buildCharts(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharts(LiftState state) {
    final history = state.selectedExerciseHistory;
    if (history == null) {
      return const SizedBox.shrink();
    }

    final e1rmHistory = history['e1rm_history'] as List<E1rmHistoryEntry>?;
    final tmHistory = history['tm_history'] as List<E1rmHistoryEntry>?;

    return Column(
      children: [
        if (e1rmHistory != null && e1rmHistory.isNotEmpty)
          E1rmChartWidget(
            entries: e1rmHistory,
            label: 'e1RM',
            lineColor: AppTheme.primary,
          ),
        if (tmHistory != null && tmHistory.isNotEmpty) ...[
          const SizedBox(height: 32),
          E1rmChartWidget(
            entries: tmHistory,
            label: 'Training Max',
            lineColor: Colors.amber,
          ),
        ],
        if ((e1rmHistory == null || e1rmHistory.isEmpty) &&
            (tmHistory == null || tmHistory.isEmpty))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No history available for this exercise.',
                style: TextStyle(color: AppTheme.mutedForeground),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSheetError(ThemeData theme, String error) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.destructive,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
