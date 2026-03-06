import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/achievement_celebration_overlay.dart'
    show achievementIconMap;
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../data/models/achievement_model.dart';

/// Single achievement badge tile for the grid.
class AchievementBadge extends StatelessWidget {
  final AchievementModel achievement;

  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = achievement.earned;
    final iconData = achievementIconMap[achievement.iconName] ?? Icons.emoji_events;

    return Semantics(
      label: earned
          ? '${achievement.name}, earned'
          : '${achievement.name}, locked',
      button: true,
      child: AdaptiveTappable(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 12,
              fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final theme = Theme.of(context);
    final earned = achievement.earned;
    final iconData = achievementIconMap[achievement.iconName] ?? Icons.emoji_events;

    showAdaptiveBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    iconData,
                    color: earned
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      achievement.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
