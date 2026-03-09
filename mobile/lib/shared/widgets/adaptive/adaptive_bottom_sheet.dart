import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';

/// Shows a platform-adaptive modal bottom sheet.
///
/// iOS: Uses [showCupertinoModalPopup] with a rounded container.
/// Android: Uses [showModalBottomSheet] with Material styling.
///
/// For simple action lists, prefer [showAdaptiveActionSheet] instead.
Future<T?> showAdaptiveBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  double? maxHeight,
}) {
  HapticService.lightTap();

  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

  if (isIOS) {
    return showCupertinoModalPopup<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: isDismissible,
      builder: (ctx) => _IOSBottomSheet(
        maxHeight: maxHeight,
        enableDrag: enableDrag,
        child: builder(ctx),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: builder,
  );
}

class _IOSBottomSheet extends StatefulWidget {
  final Widget child;
  final double? maxHeight;
  final bool enableDrag;

  const _IOSBottomSheet({
    required this.child,
    this.maxHeight,
    this.enableDrag = true,
  });

  @override
  State<_IOSBottomSheet> createState() => _IOSBottomSheetState();
}

class _IOSBottomSheetState extends State<_IOSBottomSheet> {
  double _dragOffset = 0;
  static const _dismissThreshold = 100.0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enableDrag) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enableDrag) return;
    if (_dragOffset > _dismissThreshold ||
        details.velocity.pixelsPerSecond.dy > 500) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bgColor = CupertinoColors.systemBackground.resolveFrom(context);

    return AnimatedContainer(
      duration: _dragOffset == 0
          ? const Duration(milliseconds: 200)
          : Duration.zero,
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _dragOffset, 0),
      child: Material(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: widget.maxHeight ?? mq.size.height * 0.85,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                GestureDetector(
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 4,
                      left: 48,
                      right: 48,
                    ),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey3
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
