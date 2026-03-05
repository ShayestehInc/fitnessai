import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/haptic_service.dart';
import 'adaptive/adaptive_icons.dart';

class AdminNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminNavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor,
              width: defaultTargetPlatform == TargetPlatform.iOS ? 0.5 : 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: AdaptiveIcons.dashboard,
                  label: 'Dashboard',
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => navigationShell.goBranch(0),
                ),
                _NavItem(
                  icon: AdaptiveIcons.trainers,
                  label: 'Trainers',
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => navigationShell.goBranch(1),
                ),
                _NavItem(
                  icon: AdaptiveIcons.subscriptions,
                  label: 'Subscriptions',
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => navigationShell.goBranch(2),
                ),
                _NavItem(
                  icon: AdaptiveIcons.settingsFilled,
                  label: 'Settings',
                  isSelected: navigationShell.currentIndex == 3,
                  onTap: () => navigationShell.goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final mutedColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : mutedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : mutedColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
