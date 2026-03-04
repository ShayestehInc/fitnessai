import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A platform-adaptive linear progress indicator.
///
/// iOS: Thinner bar with rounded caps and Cupertino-style colors.
/// Android: Standard [LinearProgressIndicator].
class AdaptiveProgressBar extends StatelessWidget {
  final double? value;
  final Color? color;
  final Color? backgroundColor;
  final double? minHeight;

  const AdaptiveProgressBar({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: value,
          color: color ?? CupertinoColors.activeBlue,
          backgroundColor: backgroundColor ??
              CupertinoColors.systemGrey5.resolveFrom(context),
          minHeight: minHeight ?? 3,
        ),
      );
    }

    return LinearProgressIndicator(
      value: value,
      color: color,
      backgroundColor: backgroundColor,
      minHeight: minHeight,
    );
  }
}
