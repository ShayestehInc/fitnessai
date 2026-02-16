import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/models/ambassador_models.dart';

/// Bar chart displaying monthly earnings for the last 6 months.
///
/// Shows an empty state when [monthlyEarnings] is empty.
/// Theme-aware colors and accessibility labels included.
class MonthlyEarningsChart extends StatelessWidget {
  final List<MonthlyEarnings> monthlyEarnings;

  const MonthlyEarningsChart({super.key, required this.monthlyEarnings});

  static const double _chartHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Earnings',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (monthlyEarnings.isEmpty)
          _buildEmptyState(theme)
        else
          _buildChart(theme),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Semantics(
      label: 'No earnings data yet',
      child: Container(
        height: _chartHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No earnings data yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    final barColor = theme.colorScheme.primary.withValues(alpha: 0.8);
    final maxEarning = _maxEarning;
    // Add 20% headroom to max so bars don't touch the top
    final maxY = maxEarning > 0 ? maxEarning * 1.2 : 100.0;

    return Semantics(
      label:
          'Monthly earnings chart showing earnings for the last 6 months',
      child: Container(
        height: _chartHeight,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            barGroups: _buildBarGroups(barColor),
            titlesData: _buildTitlesData(theme),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.dividerColor,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) =>
                    theme.colorScheme.surfaceContainerHighest,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final entry = monthlyEarnings[group.x.toInt()];
                  final monthLabel = _formatMonthLabel(entry.month);
                  return BarTooltipItem(
                    '$monthLabel\n\$${_formatAmount(entry.earnings)}',
                    TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(Color barColor) {
    return List.generate(monthlyEarnings.length, (index) {
      final entry = monthlyEarnings[index];
      final earningValue = double.tryParse(entry.earnings) ?? 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: earningValue,
            color: barColor,
            width: monthlyEarnings.length <= 3 ? 32 : 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
        showingTooltipIndicators: [],
        barsSpace: 4,
      );
    });
  }

  FlTitlesData _buildTitlesData(ThemeData theme) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (value, meta) {
            if (value == meta.max || value == meta.min) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '\$${value.toInt()}',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 10,
                ),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= monthlyEarnings.length) {
              return const SizedBox.shrink();
            }
            final label = _formatMonthLabel(monthlyEarnings[index].month);
            return Semantics(
              label:
                  '$label: \$${_formatAmount(monthlyEarnings[index].earnings)}',
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double get _maxEarning {
    double max = 0;
    for (final entry in monthlyEarnings) {
      final value = double.tryParse(entry.earnings) ?? 0.0;
      if (value > max) max = value;
    }
    return max;
  }

  /// Converts "2025-09" to "Sep".
  String _formatMonthLabel(String yearMonth) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final parts = yearMonth.split('-');
    if (parts.length == 2) {
      final monthNum = int.tryParse(parts[1]);
      if (monthNum != null && monthNum >= 1 && monthNum <= 12) {
        return months[monthNum - 1];
      }
    }
    return yearMonth;
  }

  /// Formats amount string to 2 decimal places.
  String _formatAmount(String amount) {
    final value = double.tryParse(amount);
    if (value == null) return amount;
    return value.toStringAsFixed(2);
  }
}

/// Shimmer/skeleton placeholder for the chart while loading.
class MonthlyEarningsChartSkeleton extends StatelessWidget {
  const MonthlyEarningsChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 140,
          height: 16,
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (index) {
                // Varying heights for visual skeleton
                final heights = [60.0, 90.0, 45.0, 110.0, 70.0, 85.0];
                return Container(
                  width: 20,
                  height: heights[index],
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
