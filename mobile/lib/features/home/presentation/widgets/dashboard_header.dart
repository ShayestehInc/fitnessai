import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../community/presentation/providers/announcement_provider.dart';

/// Dashboard greeting header with avatar, date, notification bell, and coach badge.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final firstName = (user?.firstName ?? '').trim();
    final greeting = firstName.isNotEmpty ? 'Hey, $firstName!' : 'Hey there!';
    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());
    final trainer = user?.trainer;
    final trainerName = trainer != null
        ? [trainer.firstName, trainer.lastName].where((n) => n != null && n.isNotEmpty).join(' ')
        : null;
    final initials = _initials(user?.firstName, user?.lastName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 14,
                ),
              ),
              if (trainerName != null && trainerName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Coached by $trainerName',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Action buttons
        _TvModeButton(),
        const SizedBox(width: 4),
        _NotificationBell(),
        const SizedBox(width: 8),
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primary,
          backgroundImage: user?.profileImage != null
              ? NetworkImage(user!.profileImage!)
              : null,
          child: user?.profileImage == null
              ? Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
      ],
    );
  }

  String _initials(String? first, String? last) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    if (f.isEmpty && l.isEmpty) return '?';
    if (l.isEmpty) return f[0].toUpperCase();
    return '${f.isNotEmpty ? f[0] : ''}${l[0]}'.toUpperCase();
  }
}

class _TvModeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    return IconButton(
      onPressed: () => context.push('/tv-mode'),
      icon: const Icon(Icons.tv, color: AppTheme.mutedForeground, size: 22),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeCount = ref.watch(
      announcementProvider.select((s) => s.unreadCount),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => context.push('/community/announcements'),
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppTheme.mutedForeground,
            size: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppTheme.destructive,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
