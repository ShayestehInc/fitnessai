import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_status.dart';

/// A thin persistent banner that shows connectivity and sync state.
///
/// States:
/// - Offline: amber banner with cloud_off icon
/// - Syncing: blue banner with progress indicator
/// - All synced: green banner that auto-dismisses after 3 seconds
/// - Failed: red banner with tap-to-retry text
/// - Hidden: no banner (online + idle)
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  _BannerState _currentState = _BannerState.hidden;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final syncAsync = ref.watch(syncStatusProvider);
    final failedCountAsync = ref.watch(failedSyncCountProvider);

    final isOffline = connectivityAsync.when(
      data: (s) => s == ConnectivityStatus.offline,
      loading: () => false,
      error: (_, __) => false,
    );

    final syncStatus = syncAsync.when(
      data: (s) => s,
      loading: () => const SyncStatus.idle(),
      error: (_, __) => const SyncStatus.idle(),
    );

    final failedCount = failedCountAsync.when(
      data: (c) => c,
      loading: () => 0,
      error: (_, __) => 0,
    );

    // Determine banner state
    final newState = _determineBannerState(isOffline, syncStatus, failedCount);

    // Handle auto-dismiss for "all synced"
    if (newState != _currentState) {
      _dismissTimer?.cancel();
      if (newState == _BannerState.allSynced) {
        _dismissTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _currentState = _BannerState.hidden);
          }
        });
      }
      _currentState = newState;
    }

    if (_currentState == _BannerState.hidden) {
      return const SizedBox.shrink();
    }

    return Semantics(
      liveRegion: true,
      label: _semanticsLabel(_currentState, syncStatus, failedCount),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _buildBanner(context, syncStatus, failedCount),
      ),
    );
  }

  _BannerState _determineBannerState(
    bool isOffline,
    SyncStatus syncStatus,
    int failedCount,
  ) {
    if (isOffline) return _BannerState.offline;
    if (syncStatus.state == SyncState.syncing) return _BannerState.syncing;
    if (syncStatus.state == SyncState.allSynced) return _BannerState.allSynced;
    if (failedCount > 0) return _BannerState.failed;
    if (syncStatus.state == SyncState.hasFailed) return _BannerState.failed;
    return _BannerState.hidden;
  }

  Widget _buildBanner(
    BuildContext context,
    SyncStatus syncStatus,
    int failedCount,
  ) {
    switch (_currentState) {
      case _BannerState.offline:
        return _BannerContent(
          key: const ValueKey('offline'),
          backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          icon: Icons.cloud_off,
          iconColor: const Color(0xFFF59E0B),
          text: 'You are offline',
          textColor: const Color(0xFFF59E0B),
        );
      case _BannerState.syncing:
        final progressText = syncStatus.progress?.displayText ?? 'Syncing...';
        return _BannerContent(
          key: const ValueKey('syncing'),
          backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          icon: Icons.cloud_upload,
          iconColor: const Color(0xFF3B82F6),
          text: progressText,
          textColor: const Color(0xFF3B82F6),
          showProgressIndicator: true,
        );
      case _BannerState.allSynced:
        return _BannerContent(
          key: const ValueKey('synced'),
          backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
          icon: Icons.cloud_done,
          iconColor: const Color(0xFF22C55E),
          text: 'All changes synced',
          textColor: const Color(0xFF22C55E),
        );
      case _BannerState.failed:
        return GestureDetector(
          onTap: () => _showFailedSyncSheet(context),
          child: _BannerContent(
            key: const ValueKey('failed'),
            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
            icon: Icons.error_outline,
            iconColor: const Color(0xFFEF4444),
            text: '$failedCount item${failedCount == 1 ? '' : 's'} '
                'failed to sync. Tap to retry.',
            textColor: const Color(0xFFEF4444),
          ),
        );
      case _BannerState.hidden:
        return const SizedBox.shrink();
    }
  }

  void _showFailedSyncSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FailedSyncSheetContent(),
    );
  }

  String _semanticsLabel(
    _BannerState state,
    SyncStatus syncStatus,
    int failedCount,
  ) {
    switch (state) {
      case _BannerState.offline:
        return 'You are offline';
      case _BannerState.syncing:
        return syncStatus.progress?.displayText ?? 'Syncing data';
      case _BannerState.allSynced:
        return 'All changes synced';
      case _BannerState.failed:
        return '$failedCount items failed to sync';
      case _BannerState.hidden:
        return '';
    }
  }
}

enum _BannerState { offline, syncing, allSynced, failed, hidden }

/// The actual banner row content.
class _BannerContent extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;
  final bool showProgressIndicator;

  const _BannerContent({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
    this.showProgressIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 28,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showProgressIndicator)
            SizedBox(
              width: 60,
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: iconColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet showing failed sync items with retry/delete actions.
class _FailedSyncSheetContent extends ConsumerWidget {
  const _FailedSyncSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failedCount = ref.watch(failedSyncCountProvider);
    final syncService = ref.watch(syncServiceProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Failed Sync Items',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        syncService?.triggerSync();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Retry All'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: failedCount.when(
                  data: (count) {
                    if (count == 0) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No failed items',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          '$count item${count == 1 ? '' : 's'} failed to sync. '
                          'Tap "Retry All" to attempt syncing again.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Error: $e'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
