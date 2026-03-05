import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/providers/notification_preferences_provider.dart';

/// Category metadata used to render grouped toggle tiles.
class _CategoryMeta {
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;

  const _CategoryMeta({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

/// Section header + its categories.
class _Section {
  final String title;
  final List<_CategoryMeta> categories;

  const _Section({required this.title, required this.categories});
}

// ---------------------------------------------------------------------------
// Trainer categories
// ---------------------------------------------------------------------------
const _trainerSections = [
  _Section(
    title: 'Trainee Activity',
    categories: [
      _CategoryMeta(
        key: 'trainee_workout',
        label: 'Workout Logged',
        subtitle: 'When a trainee logs a workout',
        icon: Icons.fitness_center,
      ),
      _CategoryMeta(
        key: 'trainee_weight_checkin',
        label: 'Weight Check-in',
        subtitle: 'When a trainee records their weight',
        icon: Icons.monitor_weight_outlined,
      ),
      _CategoryMeta(
        key: 'trainee_started_workout',
        label: 'Workout Started',
        subtitle: 'When a trainee starts a workout session',
        icon: Icons.play_circle_outline,
      ),
      _CategoryMeta(
        key: 'trainee_finished_workout',
        label: 'Workout Finished',
        subtitle: 'When a trainee finishes a workout session',
        icon: Icons.check_circle_outline,
      ),
      _CategoryMeta(
        key: 'churn_alert',
        label: 'Churn Alert',
        subtitle: 'When a trainee is at risk of churning',
        icon: Icons.warning_amber_outlined,
      ),
    ],
  ),
  _Section(
    title: 'Communication',
    categories: [
      _CategoryMeta(
        key: 'new_message',
        label: 'New Message',
        subtitle: 'When you receive a new message',
        icon: Icons.chat_bubble_outline,
      ),
      _CategoryMeta(
        key: 'community_activity',
        label: 'Community Activity',
        subtitle: 'Posts and reactions in the community feed',
        icon: Icons.group_outlined,
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Trainee categories
// ---------------------------------------------------------------------------
const _traineeSections = [
  _Section(
    title: 'Updates',
    categories: [
      _CategoryMeta(
        key: 'trainer_announcement',
        label: 'Trainer Announcements',
        subtitle: 'Announcements from your trainer',
        icon: Icons.campaign_outlined,
      ),
      _CategoryMeta(
        key: 'achievement_earned',
        label: 'Achievements',
        subtitle: 'When you earn a new achievement',
        icon: Icons.emoji_events_outlined,
      ),
    ],
  ),
  _Section(
    title: 'Communication',
    categories: [
      _CategoryMeta(
        key: 'new_message',
        label: 'New Message',
        subtitle: 'When you receive a new message',
        icon: Icons.chat_bubble_outline,
      ),
      _CategoryMeta(
        key: 'community_activity',
        label: 'Community Activity',
        subtitle: 'Posts and reactions in the community feed',
        icon: Icons.group_outlined,
      ),
    ],
  ),
];

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _osNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkOsPermission();
  }

  Future<void> _checkOsPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final enabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (mounted) {
        setState(() => _osNotificationsEnabled = enabled);
      }
    } catch (e) {
      // If firebase_messaging is unavailable (e.g. simulator), assume enabled.
      debugPrint('Failed to check OS notification permission: $e');
    }
  }

  List<_Section> _sectionsForRole(String role) {
    if (role == 'TRAINER' || role == 'ADMIN') {
      return _trainerSections;
    }
    return _traineeSections;
  }

  Future<void> _onToggle(String category, bool enabled) async {
    try {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .togglePreference(category, enabled);
    } catch (_) {
      if (mounted) {
        showAdaptiveToast(
          context,
          message: 'Failed to update preference. Please try again.',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final role = authState.user?.role ?? 'TRAINEE';
    final sections = _sectionsForRole(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: Column(
        children: [
          // OS permission banner
          if (!_osNotificationsEnabled)
            _OsPermissionBanner(onOpenSettings: _checkOsPermission),

          // Content
          Expanded(
            child: prefsAsync.when(
              loading: () => const _ShimmerSkeleton(),
              error: (error, _) => _ErrorCard(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(notificationPreferencesProvider),
              ),
              data: (prefs) => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sections.length,
                itemBuilder: (context, sectionIndex) {
                  final section = sections[sectionIndex];
                  return _SectionWidget(
                    section: section,
                    preferences: prefs,
                    onToggle: _onToggle,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OS permission banner
// ---------------------------------------------------------------------------

class _OsPermissionBanner extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _OsPermissionBanner({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications are disabled at the system level. '
              'Enable them in your device settings to receive alerts.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AdaptiveTappable(
            onTap: () async {
              await FirebaseMessaging.instance.requestPermission();
              onOpenSettings();
            },
            child: Text(
              'Enable',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section widget with header + toggle tiles
// ---------------------------------------------------------------------------

class _SectionWidget extends StatelessWidget {
  final _Section section;
  final Map<String, bool> preferences;
  final Future<void> Function(String category, bool enabled) onToggle;

  const _SectionWidget({
    required this.section,
    required this.preferences,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            section.title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...section.categories.map((cat) {
          final enabled = preferences[cat.key] ?? true;
          return SwitchListTile.adaptive(
            secondary: Icon(cat.icon, size: 22),
            title: Text(cat.label),
            subtitle: Text(
              cat.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: enabled,
            onChanged: (value) => onToggle(cat.key, value),
          );
        }),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading skeleton
// ---------------------------------------------------------------------------

class _ShimmerSkeleton extends StatelessWidget {
  const _ShimmerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(width: 120, height: 14, borderRadius: 4),
          const SizedBox(height: 16),
          for (int i = 0; i < 5; i++) ...[
            Row(
              children: [
                const LoadingShimmer(
                    width: 40, height: 40, borderRadius: 8),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingShimmer(height: 16, borderRadius: 4),
                      SizedBox(height: 6),
                      LoadingShimmer(
                          width: 180, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const LoadingShimmer(
                    width: 48, height: 28, borderRadius: 14),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          const LoadingShimmer(width: 120, height: 14, borderRadius: 4),
          const SizedBox(height: 16),
          for (int i = 0; i < 2; i++) ...[
            Row(
              children: [
                const LoadingShimmer(
                    width: 40, height: 40, borderRadius: 8),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingShimmer(height: 16, borderRadius: 4),
                      SizedBox(height: 6),
                      LoadingShimmer(
                          width: 180, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const LoadingShimmer(
                    width: 48, height: 28, borderRadius: 14),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error card with retry
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load preferences',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
