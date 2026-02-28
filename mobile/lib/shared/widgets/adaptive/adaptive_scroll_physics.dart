import 'package:flutter/material.dart';

/// Returns platform-native always-scrollable physics.
///
/// iOS: [BouncingScrollPhysics] (rubber-band overscroll).
/// Android: [ClampingScrollPhysics] (glow overscroll).
ScrollPhysics adaptiveAlwaysScrollablePhysics(BuildContext context) {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  return AlwaysScrollableScrollPhysics(
    parent: isIOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics(),
  );
}
