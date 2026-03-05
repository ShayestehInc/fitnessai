import 'package:flutter/material.dart';
import '../../data/models/habit_model.dart';
import 'streak_badge.dart';

/// Maps icon name strings from the API to Material [IconData].
IconData _resolveIcon(String iconName) {
  const iconMap = <String, IconData>{
    'check_circle': Icons.check_circle_outline,
    'fitness_center': Icons.fitness_center,
    'local_drink': Icons.local_drink,
    'bedtime': Icons.bedtime,
    'self_improvement': Icons.self_improvement,
    'directions_run': Icons.directions_run,
    'restaurant': Icons.restaurant,
    'medication': Icons.medication,
    'book': Icons.book,
    'emoji_food_beverage': Icons.emoji_food_beverage,
  };
  return iconMap[iconName] ?? Icons.check_circle_outline;
}

/// A single habit row with an animated checkbox, icon, name, and streak badge.
class HabitCheckTile extends StatefulWidget {
  final DailyHabitModel habit;
  final int currentStreak;
  final VoidCallback onToggle;

  const HabitCheckTile({
    super.key,
    required this.habit,
    required this.currentStreak,
    required this.onToggle,
  });

  @override
  State<HabitCheckTile> createState() => _HabitCheckTileState();
}

class _HabitCheckTileState extends State<HabitCheckTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.habit.completed) {
      _controller.forward(from: 0);
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = widget.habit.completed;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: completed
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: completed
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            // Animated checkbox
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: completed
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),

            // Habit icon
            Icon(
              _resolveIcon(widget.habit.icon),
              size: 22,
              color: completed
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 12),

            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.habit.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                      decoration:
                          completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (widget.habit.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.habit.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Streak badge
            StreakBadge(streakCount: widget.currentStreak),
          ],
        ),
      ),
    );
  }
}
