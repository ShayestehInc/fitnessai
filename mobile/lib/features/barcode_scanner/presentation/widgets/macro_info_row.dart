import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A single row displaying a macro nutrient name, its value, and a visual
/// progress bar sized relative to an optional [maxValue].
class MacroInfoRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final double maxValue;

  const MacroInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.unit = 'g',
    required this.color,
    this.maxValue = 300,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.zinc400,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: AppTheme.zinc800,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              '${value.toStringAsFixed(1)}$unit',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.foreground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
