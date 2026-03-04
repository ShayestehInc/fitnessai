import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';

/// A platform-adaptive pull-to-refresh wrapper.
///
/// iOS: Styled with [CupertinoColors] and thinner stroke for native feel.
/// Android: Standard [RefreshIndicator].
///
/// Adds haptic feedback on pull-to-refresh trigger on both platforms.
class AdaptiveRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double? displacement;
  final Color? color;

  const AdaptiveRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return RefreshIndicator(
      onRefresh: () async {
        HapticService.lightTap();
        await onRefresh();
      },
      color: color ?? (isIOS ? CupertinoColors.activeBlue : null),
      strokeWidth: isIOS ? 2.0 : 2.5,
      displacement: displacement ?? 40.0,
      child: child,
    );
  }
}
