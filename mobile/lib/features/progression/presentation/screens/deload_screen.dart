import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/progression_models.dart';
import '../providers/progression_provider.dart';
import '../widgets/deload_recommendation_card.dart';

class DeloadScreen extends ConsumerStatefulWidget {
  final int programId;

  const DeloadScreen({
    super.key,
    required this.programId,
  });

  @override
  ConsumerState<DeloadScreen> createState() => _DeloadScreenState();
}

class _DeloadScreenState extends ConsumerState<DeloadScreen> {
  bool _isApplying = false;

  Future<void> _handleAcceptDeload(
    DeloadRecommendationModel recommendation,
  ) async {
    setState(() => _isApplying = true);
    try {
      final repository = ref.read(progressionRepositoryProvider);
      // Apply deload to the next week (current week + 1).
      final result = await repository.applyDeload(widget.programId, 0);
      if (!mounted) return;

      if (result['success'] == true) {
        showAdaptiveToast(
          context,
          message: 'Deload applied successfully',
          type: ToastType.success,
        );
        ref.invalidate(deloadCheckProvider(widget.programId));
      } else {
        showAdaptiveToast(
          context,
          message: result['error'] as String? ?? 'Failed to apply deload',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  void _handleDismissDeload() {
    showAdaptiveToast(
      context,
      message: 'Deload recommendation dismissed',
      type: ToastType.info,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deloadAsync = ref.watch(deloadCheckProvider(widget.programId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deload Detection'),
      ),
      body: deloadAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, stack) => _buildErrorState(theme, error),
        data: (recommendation) => _buildContent(theme, recommendation),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
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
              'Failed to Check Deload Status',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(
                deloadCheckProvider(widget.programId),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    DeloadRecommendationModel recommendation,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(deloadCheckProvider(widget.programId));
      },
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DeloadRecommendationCard(
            recommendation: recommendation,
            isLoading: _isApplying,
            onAccept: () => _handleAcceptDeload(recommendation),
            onDismiss: _handleDismissDeload,
          ),
          if (recommendation.weeklyVolumeTrend.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildVolumeTrendChart(theme, recommendation),
          ],
          if (recommendation.fatigueSignals.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildFatigueSignals(theme, recommendation),
          ],
        ],
      ),
    );
  }

  Widget _buildVolumeTrendChart(
    ThemeData theme,
    DeloadRecommendationModel recommendation,
  ) {
    final trend = recommendation.weeklyVolumeTrend;
    final maxVolume =
        trend.fold<double>(0, (max, v) => v > max ? v : max);
    final chartMax = maxVolume > 0 ? maxVolume * 1.2 : 100.0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Volume Trend',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Total training volume over recent weeks',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.zinc700,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)} vol',
                        const TextStyle(
                          color: AppTheme.foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final weekIndex = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'W${weekIndex + 1}',
                            style: const TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 4,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: AppTheme.zinc700,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  trend.length,
                  (index) {
                    final isLast = index == trend.length - 1;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: trend[index],
                          width: 24,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          color: isLast
                              ? (recommendation.needsDeload
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF22C55E))
                              : AppTheme.primary,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFatigueSignals(
    ThemeData theme,
    DeloadRecommendationModel recommendation,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Fatigue Signals',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendation.fatigueSignals.map(
            (signal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      signal,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.zinc300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
