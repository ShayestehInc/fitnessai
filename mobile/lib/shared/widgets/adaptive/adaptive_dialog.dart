import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a platform-adaptive confirmation dialog.
///
/// iOS: [CupertinoAlertDialog] via [showCupertinoDialog].
/// Android: [AlertDialog] via [showDialog].
///
/// Returns `true` if confirmed, `false` if cancelled, `null` if dismissed.
Future<bool?> showAdaptiveConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
}) {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

  if (isIOS) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: isDestructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

/// A single action for [showAdaptiveActionSheet].
class AdaptiveAction {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  const AdaptiveAction({
    required this.label,
    this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });
}

/// Shows a platform-adaptive action sheet.
///
/// iOS: [CupertinoActionSheet] via [showCupertinoModalPopup].
/// Android: [showModalBottomSheet] with [ListTile] items.
Future<void> showAdaptiveActionSheet({
  required BuildContext context,
  required List<AdaptiveAction> actions,
  String? title,
  String cancelText = 'Cancel',
}) {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

  if (isIOS) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: title != null ? Text(title) : null,
        actions: actions.map((action) {
          return CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            onPressed: () {
              Navigator.of(ctx).pop();
              action.onPressed();
            },
            child: Text(action.label),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(cancelText),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...actions.map((action) {
            return ListTile(
              leading: action.icon != null
                  ? Icon(
                      action.icon,
                      color: action.isDestructive
                          ? Theme.of(ctx).colorScheme.error
                          : null,
                    )
                  : null,
              title: Text(
                action.label,
                style: action.isDestructive
                    ? TextStyle(color: Theme.of(ctx).colorScheme.error)
                    : null,
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                action.onPressed();
              },
            );
          }),
          ListTile(
            leading: const Icon(Icons.close),
            title: Text(cancelText),
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    ),
  );
}
