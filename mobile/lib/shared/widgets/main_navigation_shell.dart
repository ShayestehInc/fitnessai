import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/trainer/presentation/providers/trainer_provider.dart';
import '../../features/trainer/presentation/widgets/impersonation_banner.dart';

class MainNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impersonationState = ref.watch(impersonationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Show impersonation banner when trainer is viewing as trainee
          if (impersonationState.isImpersonating) const ImpersonationBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => _onTap(context, 0),
                ),
                _NavItem(
                  icon: Icons.restaurant_outlined,
                  activeIcon: Icons.restaurant,
                  label: 'Diet',
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => _onTap(context, 1),
                ),
                _NavItem(
                  icon: Icons.fitness_center_outlined,
                  activeIcon: Icons.fitness_center,
                  label: 'Logbook',
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => _onTap(context, 2),
                ),
                _NavItem(
                  icon: Icons.people_outlined,
                  activeIcon: Icons.people,
                  label: 'Community',
                  isSelected: navigationShell.currentIndex == 3,
                  onTap: () => _onTap(context, 3),
                ),
                _NavItem(
                  icon: Icons.play_circle_outline,
                  activeIcon: Icons.play_circle,
                  label: 'TV',
                  isSelected: navigationShell.currentIndex == 4,
                  onTap: () => _onTap(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : mutedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : mutedColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
