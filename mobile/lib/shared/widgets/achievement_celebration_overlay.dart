import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/services/haptic_service.dart';
import '../../features/community/data/models/achievement_model.dart';

/// Map of backend icon_name strings to Flutter IconData.
/// Mirrors the map in achievement_badge.dart.
const Map<String, IconData> achievementIconMap = {
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

/// Gold accent color for the achievement glow effect.
const Color _achievementGold = Color(0xFFFFD700);

/// Shows a single achievement celebration overlay on the given [overlay].
///
/// Returns a Future that completes when the overlay is fully dismissed.
Future<void> showAchievementCelebration({
  required OverlayState overlay,
  required NewAchievementModel achievement,
  required double topPadding,
  Duration displayDuration = const Duration(seconds: 4),
}) {
  final completer = Completer<void>();

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AchievementCelebrationWidget(
      achievement: achievement,
      topPadding: topPadding,
      displayDuration: displayDuration,
      onDismissed: () {
        entry.remove();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    ),
  );

  HapticService.success();
  overlay.insert(entry);

  return completer.future;
}

class _AchievementCelebrationWidget extends StatefulWidget {
  final NewAchievementModel achievement;
  final double topPadding;
  final Duration displayDuration;
  final VoidCallback onDismissed;

  const _AchievementCelebrationWidget({
    required this.achievement,
    required this.topPadding,
    required this.displayDuration,
    required this.onDismissed,
  });

  @override
  State<_AchievementCelebrationWidget> createState() =>
      _AchievementCelebrationWidgetState();
}

class _AchievementCelebrationWidgetState
    extends State<_AchievementCelebrationWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _pulseAnimation;

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _entranceController.forward();
    _pulseController.repeat(reverse: true);

    _scheduleAutoDismiss();
  }

  void _scheduleAutoDismiss() {
    Future.delayed(widget.displayDuration, () {
      if (mounted && !_dismissed) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    _pulseController.stop();
    await _entranceController.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconData =
        achievementIconMap[widget.achievement.iconName] ?? Icons.emoji_events;

    return Positioned(
      top: widget.topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -100) {
                _dismiss();
              }
            },
            child: Semantics(
              liveRegion: true,
              label:
                  'Achievement earned: ${widget.achievement.name}. ${widget.achievement.description}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xE6181818),
                      border: Border.all(
                        color: _achievementGold.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildBadgeIcon(iconData),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextContent(),
                        ),
                        const Icon(
                          Icons.close,
                          color: Color(0x80FFFFFF),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(IconData iconData) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _achievementGold.withValues(alpha: 0.15),
            border: Border.all(
              color: _achievementGold.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _achievementGold.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            iconData,
            size: 26,
            color: _achievementGold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Achievement Unlocked!',
          style: TextStyle(
            color: _achievementGold,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.achievement.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          widget.achievement.description,
          style: const TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.normal,
            decoration: TextDecoration.none,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
