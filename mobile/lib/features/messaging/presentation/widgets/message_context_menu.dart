import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/message_model.dart';
import 'edit_message_sheet.dart';

/// Shows a bottom sheet context menu for a message.
///
/// Own messages: Edit (if within window), Delete, Copy.
/// Other's messages: Copy only.
void showMessageContextMenu({
  required BuildContext context,
  required MessageModel message,
  required bool isMine,
  void Function(String newContent)? onEdit,
  VoidCallback? onDelete,
}) {
  final theme = Theme.of(context);
  final canEdit = isMine && !message.isDeleted && !message.isEditWindowExpired;
  final canDelete = isMine && !message.isDeleted;
  final canCopy = message.content.isNotEmpty && !message.isDeleted;

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (canCopy)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              if (isMine && !message.isDeleted) ...[
                ListTile(
                  leading: Icon(
                    Icons.edit,
                    color: canEdit ? null : theme.disabledColor,
                  ),
                  title: Text(
                    'Edit',
                    style: TextStyle(
                      color: canEdit ? null : theme.disabledColor,
                    ),
                  ),
                  subtitle: canEdit
                      ? null
                      : Text(
                          'Edit window expired',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                  enabled: canEdit,
                  onTap: canEdit
                      ? () {
                          Navigator.of(sheetContext).pop();
                          _showEditSheet(
                            context: context,
                            message: message,
                            onEdit: onEdit,
                          );
                        }
                      : null,
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: canDelete
                        ? theme.colorScheme.error
                        : theme.disabledColor,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(
                      color: canDelete
                          ? theme.colorScheme.error
                          : theme.disabledColor,
                    ),
                  ),
                  enabled: canDelete,
                  onTap: canDelete
                      ? () {
                          Navigator.of(sheetContext).pop();
                          _showDeleteConfirmation(
                            context: context,
                            onDelete: onDelete,
                          );
                        }
                      : null,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

void _showEditSheet({
  required BuildContext context,
  required MessageModel message,
  void Function(String newContent)? onEdit,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return EditMessageSheet(
        initialContent: message.content,
        hasImage: message.hasImage,
        onSave: (newContent) {
          Navigator.of(sheetContext).pop();
          onEdit?.call(newContent);
        },
        onCancel: () => Navigator.of(sheetContext).pop(),
      );
    },
  );
}

void _showDeleteConfirmation({
  required BuildContext context,
  VoidCallback? onDelete,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: const Text('Delete message'),
        content: const Text(
          "Delete this message? This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}
