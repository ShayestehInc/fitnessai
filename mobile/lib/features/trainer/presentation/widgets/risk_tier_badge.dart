import 'package:flutter/material.dart';

/// Color-coded pill badge for churn risk tiers.
class RiskTierBadge extends StatelessWidget {
  final String tier;

  const RiskTierBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _tierStyle(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (Color, String) _tierStyle(String tier) {
    return switch (tier) {
      'critical' => (const Color(0xFFEF4444), 'Critical'),
      'high' => (const Color(0xFFF97316), 'High'),
      'medium' => (const Color(0xFFEAB308), 'Medium'),
      'low' => (const Color(0xFF22C55E), 'Low'),
      _ => (const Color(0xFF71717A), tier),
    };
  }
}
