import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/achievement_model.dart';

/// Map of Material icon name strings to IconData.
/// This maps the backend `icon_name` field to actual Flutter icons.
const Map<String, IconData> _iconMap = {
  'directions_walk': Icons.directions_walk,
  'fitness_center': Icons.fitness_center,
  'local_fire_department': Icons.local_fire_department,
  'military_tech': Icons.military_tech,
  'bolt': Icons.bolt,
  'whatshot': Icons.whatshot,
  'stars': Icons.stars,
  'monitor_weight': Icons.monitor_weight,
  'trending_up': Icons.trending_up,
  'insights': Icons.insights,
  'restaurant': Icons.restaurant,
  'emoji_food_beverage': Icons.emoji_food_beverage,
  'workspace_premium': Icons.workspace_premium,
  'school': Icons.school,
  'emoji_events': Icons.emoji_events,
};

/// Single achievement badge tile for the grid.
class AchievementBadge extends StatelessWidget {
  final AchievementModel achievement;

  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = achievement.earned;
    final iconData = _iconMap[achievement.iconName] ?? Icons.emoji_events;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.dividerColor.withValues(alpha: 0.5),
              border: Border.all(
                color: earned
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: 2,
              ),
            ),
            child: Icon(
              iconData,
              size: 28,
              color: earned
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: earned
                  ? theme.textTheme.bodyLarge?.color
                  : theme.textTheme.bodySmall?.color,
              fontSize: 11,
              fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final theme = Theme.of(context);
    final earned = achievement.earned;
    final iconData = _iconMap[achievement.iconName] ?? Icons.emoji_events;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              iconData,
              color: earned
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(achievement.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            if (earned && achievement.earnedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Earned on ${DateFormat('MMM d, yyyy').format(achievement.earnedAt!)}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (!earned) ...[
              const SizedBox(height: 12),
              Text(
                'Not yet earned',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
