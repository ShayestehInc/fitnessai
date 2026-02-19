import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/widgets/admin_impersonation_banner.dart';
import '../../features/messaging/presentation/providers/messaging_provider.dart';

class TrainerNavigationShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const TrainerNavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<TrainerNavigationShell> createState() =>
      _TrainerNavigationShellState();
}

class _TrainerNavigationShellState
    extends ConsumerState<TrainerNavigationShell> {
  @override
  void initState() {
    super.initState();
    // Refresh unread count once on first mount, not on every rebuild
    ref.read(unreadMessageCountProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = ref.watch(unreadMessageCountProvider);

    return Scaffold(
      body: AdminImpersonationBannerWrapper(child: widget.navigationShell),
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
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: widget.navigationShell.currentIndex == 0,
                  onTap: () => _onTap(context, 0),
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Trainees',
                  isSelected: widget.navigationShell.currentIndex == 1,
                  onTap: () => _onTap(context, 1),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Messages',
                  isSelected: widget.navigationShell.currentIndex == 2,
                  onTap: () => _onTap(context, 2),
                  badgeCount: unreadCount,
                ),
                _NavItem(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: 'Programs',
                  isSelected: widget.navigationShell.currentIndex == 3,
                  onTap: () => _onTap(context, 3),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  isSelected: widget.navigationShell.currentIndex == 4,
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
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? primaryColor : mutedColor,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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
