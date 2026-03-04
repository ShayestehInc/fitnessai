import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';

/// The semantic type of a toast message, used to determine color and icon.
enum ToastType { success, error, warning, info }

/// Shows a platform-adaptive feedback message.
///
/// iOS: Frosted-glass overlay sliding down from the top.
/// Android: Standard [SnackBar] via [ScaffoldMessenger].
void showAdaptiveToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  // Haptic feedback for error/warning toasts.
  if (type == ToastType.error) {
    HapticService.error();
  } else if (type == ToastType.warning) {
    HapticService.mediumTap();
  } else if (type == ToastType.success) {
    HapticService.success();
  }

  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

  if (isIOS) {
    _showIOSToast(context, message: message, type: type, duration: duration);
    return;
  }

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: _materialColor(type, context),
      duration: duration,
    ),
  );
}

/// Shows a toast with a tappable action button.
///
/// iOS: Frosted-glass overlay with an action pill.
/// Android: [SnackBar] with [SnackBarAction].
void showAdaptiveToastWithAction(
  BuildContext context, {
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

  if (isIOS) {
    _showIOSToast(
      context,
      message: message,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    return;
  }

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: _materialColor(type, context),
      duration: duration,
      action: SnackBarAction(
        label: actionLabel,
        onPressed: onAction,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Android helpers
// ---------------------------------------------------------------------------

Color? _materialColor(ToastType type, BuildContext context) {
  switch (type) {
    case ToastType.success:
      return Colors.green;
    case ToastType.error:
      return Colors.red;
    case ToastType.warning:
      return Colors.orange[700];
    case ToastType.info:
      return null; // default SnackBar color
  }
}

// ---------------------------------------------------------------------------
// iOS overlay toast
// ---------------------------------------------------------------------------

OverlayEntry? _currentToast;
Timer? _currentTimer;

void _showIOSToast(
  BuildContext context, {
  required String message,
  required ToastType type,
  required Duration duration,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  // Remove any existing toast immediately
  _dismissCurrentToast();

  final overlay = Overlay.of(context);
  final mediaQuery = MediaQuery.of(context);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _IOSToastWidget(
      message: message,
      type: type,
      duration: duration,
      topPadding: mediaQuery.padding.top,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: () {
        if (_currentToast == entry) {
          _dismissCurrentToast();
        }
      },
    ),
  );

  _currentToast = entry;
  overlay.insert(entry);

  _currentTimer = Timer(duration + const Duration(milliseconds: 400), () {
    if (_currentToast == entry) {
      _dismissCurrentToast();
    }
  });
}

void _dismissCurrentToast() {
  _currentTimer?.cancel();
  _currentTimer = null;
  _currentToast?.remove();
  _currentToast = null;
}

class _IOSToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final double topPadding;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _IOSToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.topPadding,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_IOSToastWidget> createState() => _IOSToastWidgetState();
}

class _IOSToastWidgetState extends State<_IOSToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Schedule exit animation before auto-dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _iosBackgroundColor(widget.type),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(_iosIcon(widget.type), color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.actionLabel != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          widget.onAction?.call();
                          widget.onDismiss();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _iosBackgroundColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xCC22C55E); // green with opacity
      case ToastType.error:
        return const Color(0xCCEF4444); // red with opacity
      case ToastType.warning:
        return const Color(0xCCF59E0B); // amber with opacity
      case ToastType.info:
        return const Color(0xCC3B82F6); // blue with opacity
    }
  }

  static IconData _iosIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return CupertinoIcons.check_mark_circled_solid;
      case ToastType.error:
        return CupertinoIcons.xmark_circle_fill;
      case ToastType.warning:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case ToastType.info:
        return CupertinoIcons.info_circle_fill;
    }
  }
}
