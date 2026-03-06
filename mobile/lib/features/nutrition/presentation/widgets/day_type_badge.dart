import 'package:flutter/material.dart';

class DayTypeBadge extends StatelessWidget {
  final String dayType;

  const DayTypeBadge({super.key, required this.dayType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _configFor(dayType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static _DayTypeConfig _configFor(String dayType) {
    switch (dayType) {
      case 'training':
      case 'training_day':
        return _DayTypeConfig('Training Day', Colors.blue, Icons.fitness_center);
      case 'rest':
      case 'rest_day':
        return _DayTypeConfig('Rest Day', Colors.grey, Icons.weekend);
      case 'high_carb':
        return _DayTypeConfig('High Carb', Colors.green, Icons.bolt);
      case 'medium_carb':
        return _DayTypeConfig('Medium Carb', Colors.orange, Icons.balance);
      case 'low_carb':
        return _DayTypeConfig('Low Carb', Colors.red, Icons.local_fire_department);
      case 'refeed':
        return _DayTypeConfig('Refeed', Colors.teal, Icons.restaurant);
      default:
        return _DayTypeConfig('Rest Day', Colors.grey, Icons.weekend);
    }
  }
}

class _DayTypeConfig {
  final String label;
  final Color color;
  final IconData icon;

  const _DayTypeConfig(this.label, this.color, this.icon);
}
