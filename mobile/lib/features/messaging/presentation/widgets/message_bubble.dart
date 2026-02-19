import 'package:flutter/material.dart';
import '../../data/models/message_model.dart';
import 'messaging_utils.dart';

/// A single message bubble in the chat view.
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool showReadReceipt;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showReadReceipt = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                color: isMine
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isMine ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight:
                      isMine ? const Radius.circular(4) : const Radius.circular(16),
                ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimestamp(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  if (isMine && showReadReceipt) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
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
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return formatMessageTimestamp(dt);
  }
}
