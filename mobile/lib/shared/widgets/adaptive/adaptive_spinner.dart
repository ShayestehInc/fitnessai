import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A platform-adaptive loading spinner.
///
/// iOS: [CupertinoActivityIndicator].
/// Android: [CircularProgressIndicator].
class AdaptiveSpinner extends StatelessWidget {
  final bool _small;

  /// Default-size spinner suitable for full-screen or section loading states.
  const AdaptiveSpinner({super.key}) : _small = false;

  /// Small spinner (20x20) suitable for inline/button loading states.
  const AdaptiveSpinner.small({super.key}) : _small = true;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      return CupertinoActivityIndicator(radius: _small ? 10 : 14);
    }

    if (_small) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return const CircularProgressIndicator();
  }
}
