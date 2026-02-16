import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_status.dart';
import 'failed_sync_sheet.dart';

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

enum _BannerState { offline, syncing, allSynced, failed, hidden }

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  _BannerState _currentState = _BannerState.hidden;
  SyncStatus _lastSyncStatus = const SyncStatus.idle();
  int _lastFailedCount = 0;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.listen for side-effects (timers, state transitions)
    // instead of computing state inside build with setState.
    ref.listen<AsyncValue<ConnectivityStatus>>(
      connectivityStatusProvider,
      (_, next) => _recalculateBannerState(),
    );
    ref.listen<AsyncValue<SyncStatus>>(
      syncStatusProvider,
      (_, next) {
        _lastSyncStatus = next.valueOrNull ?? const SyncStatus.idle();
        _recalculateBannerState();
      },
    );
    ref.listen<AsyncValue<int>>(
      failedSyncCountProvider,
      (_, next) {
        _lastFailedCount = next.valueOrNull ?? 0;
        _recalculateBannerState();
      },
    );

    // Initial computation on first build
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final syncAsync = ref.watch(syncStatusProvider);
    final failedCountAsync = ref.watch(failedSyncCountProvider);

    final isOffline = connectivityAsync.when(
      data: (s) => s == ConnectivityStatus.offline,
      loading: () => false,
      error: (_, __) => false,
    );

    _lastSyncStatus = syncAsync.when(
      data: (s) => s,
      loading: () => const SyncStatus.idle(),
      error: (_, __) => const SyncStatus.idle(),
    );

    _lastFailedCount = failedCountAsync.when(
      data: (c) => c,
      loading: () => 0,
      error: (_, __) => 0,
    );

    // Compute the desired state without side-effects
    final desiredState =
        _determineBannerState(isOffline, _lastSyncStatus, _lastFailedCount);

    // Only update _currentState if it actually changed
    // (avoids infinite rebuild loops)
    if (desiredState != _currentState &&
        desiredState != _BannerState.hidden) {
      // Schedule the state update for after this build frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateBannerState(desiredState);
      });
    } else if (desiredState == _BannerState.hidden &&
        _currentState != _BannerState.allSynced &&
        _currentState != _BannerState.hidden) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateBannerState(_BannerState.hidden);
      });
    }

    if (_currentState == _BannerState.hidden) {
      return const SizedBox.shrink();
    }

    return Semantics(
      liveRegion: true,
      label: _semanticsLabel(
          _currentState, _lastSyncStatus, _lastFailedCount),
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
        child: _buildBanner(context, _lastSyncStatus, _lastFailedCount),
      ),
    );
  }

  void _recalculateBannerState() {
    if (!mounted) return;
    final connectivityAsync = ref.read(connectivityStatusProvider);
    final isOffline = connectivityAsync.when(
      data: (s) => s == ConnectivityStatus.offline,
      loading: () => false,
      error: (_, __) => false,
    );

    final newState =
        _determineBannerState(isOffline, _lastSyncStatus, _lastFailedCount);
    _updateBannerState(newState);
  }

  void _updateBannerState(_BannerState newState) {
    if (newState == _currentState) return;

    _dismissTimer?.cancel();

    if (newState == _BannerState.allSynced) {
      _dismissTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _currentState = _BannerState.hidden);
        }
      });
    }

    setState(() => _currentState = newState);
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
      builder: (_) => const FailedSyncSheet(),
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
