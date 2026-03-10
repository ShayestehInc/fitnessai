import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/lift_models.dart';

/// A simple line chart showing e1RM or TM history over time using CustomPaint.
class E1rmChartWidget extends StatelessWidget {
  final List<E1rmHistoryEntry> entries;
  final String label;
  final Color lineColor;

  const E1rmChartWidget({
    super.key,
    required this.entries,
    this.label = 'e1RM',
    this.lineColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: CustomPaint(
            size: Size.infinite,
            painter: _LineChartPainter(
              entries: entries,
              lineColor: lineColor,
              gridColor: AppTheme.border,
              labelColor: AppTheme.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Text(
        'No $label data yet',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final latest = entries.last;
    final first = entries.first;
    final delta = latest.value - first.value;
    final isPositive = delta >= 0;

    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.mutedForeground,
          ),
        ),
        const Spacer(),
        Text(
          '${latest.value.toStringAsFixed(1)} lbs',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
          ),
        ),
        if (entries.length > 1) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : AppTheme.destructive)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isPositive ? Colors.green : AppTheme.destructive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<E1rmHistoryEntry> entries;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  _LineChartPainter({
    required this.entries,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) {
      _paintSinglePoint(canvas, size);
      return;
    }

    final values = entries.map((e) => e.value).toList();
    final minVal = values.reduce(math.min) * 0.95;
    final maxVal = values.reduce(math.max) * 1.05;
    final range = maxVal - minVal;
    if (range == 0) return;

    const leftPadding = 40.0;
    const bottomPadding = 24.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    _drawGridLines(canvas, size, leftPadding, chartHeight, minVal, maxVal);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(leftPadding, 0, chartWidth, chartHeight));

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < entries.length; i++) {
      final x = leftPadding + (i / (entries.length - 1)) * chartWidth;
      final y = chartHeight - ((values[i] - minVal) / range * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(
      leftPadding + chartWidth,
      chartHeight,
    );
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    _drawDataPoints(canvas, entries, values, leftPadding, chartWidth,
        chartHeight, minVal, range);
    _drawDateLabels(canvas, size, leftPadding, chartWidth, chartHeight);
  }

  void _paintSinglePoint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      dotPaint,
    );
  }

  void _drawGridLines(Canvas canvas, Size size, double leftPadding,
      double chartHeight, double minVal, double maxVal) {
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 0.5;

    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = chartHeight * i / gridLines;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      final gridValue = maxVal - (maxVal - minVal) * i / gridLines;
      final tp = TextPainter(
        text: TextSpan(
          text: gridValue.toStringAsFixed(0),
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
  }

  void _drawDataPoints(
    Canvas canvas,
    List<E1rmHistoryEntry> entries,
    List<double> values,
    double leftPadding,
    double chartWidth,
    double chartHeight,
    double minVal,
    double range,
  ) {
    final dotPaint = Paint()..color = lineColor;
    final dotBorderPaint = Paint()
      ..color = AppTheme.background
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < entries.length; i++) {
      final x = leftPadding + (i / (entries.length - 1)) * chartWidth;
      final y = chartHeight - ((values[i] - minVal) / range * chartHeight);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 4, dotBorderPaint);
    }
  }

  void _drawDateLabels(Canvas canvas, Size size, double leftPadding,
      double chartWidth, double chartHeight) {
    if (entries.length <= 1) return;

    final labelIndices = <int>[0, entries.length - 1];
    if (entries.length > 4) {
      labelIndices.insert(1, entries.length ~/ 2);
    }

    for (final i in labelIndices) {
      final x = leftPadding + (i / (entries.length - 1)) * chartWidth;
      final date = entries[i].date;
      final shortDate =
          date.length >= 10 ? '${date.substring(5, 7)}/${date.substring(8, 10)}' : date;

      final tp = TextPainter(
        text: TextSpan(
          text: shortDate,
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.lineColor != lineColor;
  }
}
