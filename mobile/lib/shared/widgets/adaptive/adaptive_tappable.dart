import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A platform-adaptive tappable wrapper.
///
/// iOS: opacity fade on press (standard iOS press effect).
/// Android: Material [InkWell] with ripple.
class AdaptiveTappable extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const AdaptiveTappable({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.child,
    this.borderRadius,
    this.padding,
  });

  @override
  State<AdaptiveTappable> createState() => _AdaptiveTappableState();
}

class _AdaptiveTappableState extends State<AdaptiveTappable> {
  bool _pressed = false;

  static final bool _isIOS = defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final content = widget.padding != null
        ? Padding(padding: widget.padding!, child: widget.child)
        : widget.child;

    if (!_isIOS) {
      return InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: widget.borderRadius,
        child: content,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: content,
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }
}
