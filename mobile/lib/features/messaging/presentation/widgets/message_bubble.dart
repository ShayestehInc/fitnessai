import 'dart:io';

import 'package:flutter/material.dart';
import '../../data/models/message_model.dart';
import 'message_context_menu.dart';
import 'message_image_viewer.dart';
import 'messaging_utils.dart';

/// A single message bubble in the chat view.
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool showReadReceipt;
  final void Function(String newContent)? onEdit;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showReadReceipt = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Soft-deleted messages show a placeholder
    if (message.isDeleted) {
      return _buildDeletedBubble(context, theme);
    }

    final readStatus = message.isSendFailed
        ? ', failed to send'
        : isMine && showReadReceipt
            ? (message.isRead ? ', read' : ', sent')
            : '';
    final senderLabel = isMine ? 'You' : message.sender.displayName;
    final contentLabel = message.hasImage && message.content.isEmpty
        ? 'Photo message'
        : message.hasImage
            ? 'Photo message with text: ${message.content}'
            : message.content;
    final editedLabel = message.isEdited ? ', edited' : '';
    final semanticLabel =
        '$senderLabel: $contentLabel, ${_formatTimestamp(message.createdAt)}$editedLabel$readStatus';

    return Semantics(
      label: semanticLabel,
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isMine
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMine
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isMine
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image attachment
                      if (message.hasImage) _buildImage(context, theme),
                      // Text content
                      if (message.content.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            left: 14,
                            right: 14,
                            top: message.hasImage ? 6 : 10,
                            bottom: 10,
                          ),
                          child: Text(
                            message.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isMine
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      // Padding for image-only messages
                      if (message.content.isEmpty && message.hasImage)
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
                _buildTimestampRow(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimestampRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTimestamp(message.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color:
                  theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            Text(
              '(edited)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.5),
              ),
            ),
          ],
          if (isMine && showReadReceipt) ...[
            const SizedBox(width: 4),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 14,
              color: message.isRead
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.5),
            ),
          ],
          if (message.isSendFailed) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.error_outline,
              size: 14,
              color: theme.colorScheme.error,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeletedBubble(BuildContext context, ThemeData theme) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMine
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMine
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Text(
                'This message was deleted',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatTimestamp(message.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showMessageContextMenu(
      context: context,
      message: message,
      isMine: isMine,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

  Widget _buildImage(BuildContext context, ThemeData theme) {
    final imageUrl = message.imageUrl;
    final localPath = message.localImagePath;

    Widget imageWidget;
    if (localPath != null) {
      imageWidget = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildImageError(theme),
      );
    } else if (imageUrl != null) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _buildImageLoading(theme);
        },
        errorBuilder: (_, __, ___) => _buildImageError(theme),
      );
    } else {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        final url = imageUrl ?? localPath;
        if (url != null) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MessageImageViewer(
                imageUrl: imageUrl,
                localPath: localPath,
              ),
            ),
          );
        }
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: imageWidget,
      ),
    );
  }

  Widget _buildImageLoading(ThemeData theme) {
    return Container(
      height: 180,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildImageError(ThemeData theme) {
    return Container(
      height: 120,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            'Failed to load image',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return formatMessageTimestamp(dt);
  }
}
