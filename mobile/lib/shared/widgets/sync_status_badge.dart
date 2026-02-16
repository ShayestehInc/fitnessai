import 'package:flutter/material.dart';

import '../../core/services/sync_status.dart';

/// A small badge overlay indicating the sync status of an item.
///
/// Position this at the bottom-right corner of a card using [Positioned].
/// Badge is 16x16 with a 12px icon inside.
class SyncStatusBadge extends StatelessWidget {
  final SyncItemStatus status;

  const SyncStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticsLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: 16,
        height: 16,
        child: _buildIcon(),
      ),
    );
  }

  String get _semanticsLabel {
    switch (status) {
      case SyncItemStatus.pending:
        return 'Pending sync';
      case SyncItemStatus.syncing:
        return 'Syncing';
      case SyncItemStatus.synced:
        return '';
      case SyncItemStatus.failed:
        return 'Sync failed';
    }
  }

  Widget _buildIcon() {
    switch (status) {
      case SyncItemStatus.pending:
        return const Icon(
          Icons.cloud_off,
          size: 12,
          color: Color(0xFFF59E0B), // Amber
        );
      case SyncItemStatus.syncing:
        return const _RotatingIcon(
          icon: Icons.cloud_upload,
          size: 12,
          color: Color(0xFF3B82F6), // Blue
        );
      case SyncItemStatus.synced:
        // AC-38: Synced items show no badge -- the item is server-authoritative.
        return const SizedBox.shrink();
      case SyncItemStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 12,
          color: Color(0xFFEF4444), // Red
        );
    }
  }
}

/// An icon that continuously rotates (used for the syncing state).
class _RotatingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _RotatingIcon({
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
