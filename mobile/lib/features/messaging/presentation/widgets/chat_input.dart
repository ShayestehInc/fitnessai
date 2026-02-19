import 'package:flutter/material.dart';

/// Chat message input field with character counter and send button.
class ChatInput extends StatefulWidget {
  final Future<bool> Function(String content) onSend;
  final VoidCallback? onTypingStart;
  final bool isSending;
  final bool isDisabled;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onTypingStart,
    this.isSending = false,
    this.isDisabled = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  static const int _maxLength = 2000;
  static const double _counterThreshold = 0.9;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSend =>
      !widget.isSending &&
      !widget.isDisabled &&
      _controller.text.trim().isNotEmpty;

  bool get _showCounter =>
      _controller.text.length >= (_maxLength * _counterThreshold).round();

  bool get _isOverLimit => _controller.text.length > _maxLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showCounter)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${_controller.text.length}/$_maxLength',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isOverLimit
                          ? theme.colorScheme.error
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !widget.isDisabled,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) {
                      setState(() {});
                      widget.onTypingStart?.call();
                    },
                    decoration: InputDecoration(
                      hintText: widget.isDisabled
                          ? 'Messaging disabled'
                          : 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: _canSend && !_isOverLimit ? _handleSend : null,
                    style: IconButton.styleFrom(
                      backgroundColor: _canSend && !_isOverLimit
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: const CircleBorder(),
                    ),
                    icon: widget.isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.send,
                            size: 20,
                            color: _canSend && !_isOverLimit
                                ? theme.colorScheme.onPrimary
                                : theme.textTheme.bodySmall?.color,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSend() async {
    final content = _controller.text.trim();
    if (content.isEmpty || content.length > _maxLength) return;

    final success = await widget.onSend(content);
    if (success && mounted) {
      _controller.clear();
      setState(() {});
    }
  }
}
