import 'package:flutter/material.dart';

class IntensityLegend extends StatelessWidget {
  const IntensityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Low', style: theme.textTheme.labelSmall),
        const SizedBox(width: 8),
        Container(
          width: 120,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3F3F46),
                Color(0xFF6366F1),
                Color(0xFFF59E0B),
                Color(0xFFEF4444),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('High', style: theme.textTheme.labelSmall),
      ],
    );
  }
}
