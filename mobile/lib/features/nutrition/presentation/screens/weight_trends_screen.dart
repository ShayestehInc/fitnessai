import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/nutrition_provider.dart';
import '../../data/models/nutrition_models.dart';

class WeightTrendsScreen extends ConsumerStatefulWidget {
  const WeightTrendsScreen({super.key});

  @override
  ConsumerState<WeightTrendsScreen> createState() => _WeightTrendsScreenState();
}

class _WeightTrendsScreenState extends ConsumerState<WeightTrendsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nutritionStateProvider.notifier).loadWeightHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(nutritionStateProvider);
    final history = state.weightHistory;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Weight Trends'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/weight-checkin'),
            icon: Icon(Icons.add, color: theme.colorScheme.primary),
            label: Text('Check In', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
      body: history.isEmpty
          ? _buildEmptyState(theme)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  _buildSummaryCard(theme, history),
                  const SizedBox(height: 24),

                  // Simple chart
                  _buildSimpleChart(theme, history),
                  const SizedBox(height: 24),

                  // History list
                  Text(
                    'History',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...history.map((checkIn) => _buildHistoryRow(theme, checkIn)),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.scale,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No weight check-ins yet',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your progress by checking in regularly',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/weight-checkin'),
              icon: const Icon(Icons.add),
              label: const Text('Add First Check-In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, List<WeightCheckInModel> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    final latest = history.first;
    final latestLbs = latest.weightKg * 2.20462;

    // Calculate change from first check-in
    final oldest = history.last;
    final changeLbs = (latest.weightKg - oldest.weightKg) * 2.20462;
    final isGain = changeLbs > 0;
    final isLoss = changeLbs < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Weight',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${latestLbs.round()} lbs',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${latest.weightKg.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (history.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isLoss
                    ? Colors.green.withValues(alpha: 0.1)
                    : isGain
                        ? Colors.red.withValues(alpha: 0.1)
                        : theme.dividerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    isLoss
                        ? Icons.trending_down
                        : isGain
                            ? Icons.trending_up
                            : Icons.trending_flat,
                    color: isLoss
                        ? Colors.green
                        : isGain
                            ? Colors.red
                            : theme.textTheme.bodySmall?.color,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${changeLbs >= 0 ? '+' : ''}${changeLbs.toStringAsFixed(1)} lbs',
                    style: TextStyle(
                      color: isLoss
                          ? Colors.green
                          : isGain
                              ? Colors.red
                              : theme.textTheme.bodySmall?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'total',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(ThemeData theme, List<WeightCheckInModel> history) {
    if (history.length < 2) return const SizedBox.shrink();

    // Get last 30 days of data, reversed for chronological order
    final chartData = history.take(30).toList().reversed.toList();

    // Find min and max for scaling
    final weights = chartData.map((c) => c.weightKg).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final padding = range * 0.1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: Size.infinite,
              painter: _WeightChartPainter(
                data: chartData,
                minWeight: minWeight - padding,
                maxWeight: maxWeight + padding,
                lineColor: theme.colorScheme.primary,
                gridColor: theme.dividerColor,
                textColor: theme.textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatChartDate(chartData.first.date),
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 11,
                ),
              ),
              Text(
                _formatChartDate(chartData.last.date),
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatChartDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildHistoryRow(ThemeData theme, WeightCheckInModel checkIn) {
    final lbs = checkIn.weightKg * 2.20462;
    String formattedDate;
    try {
      final date = DateTime.parse(checkIn.date);
      formattedDate = DateFormat('EEEE, MMM d, yyyy').format(date);
    } catch (_) {
      formattedDate = checkIn.date;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (checkIn.notes.isNotEmpty)
                Text(
                  checkIn.notes,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${lbs.round()} lbs',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${checkIn.weightKg.toStringAsFixed(1)} kg',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightCheckInModel> data;
  final double minWeight;
  final double maxWeight;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _WeightChartPainter({
    required this.data,
    required this.minWeight,
    required this.maxWeight,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate points
    final points = <Offset>[];
    final range = maxWeight - minWeight;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i].weightKg - minWeight) / range) * size.height;
      points.add(Offset(x, y));
    }

    // Draw the line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    // Draw dots at each point
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
