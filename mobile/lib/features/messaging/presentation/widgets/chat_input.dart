import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Chat message input field with character counter, send button, and image picker.
class ChatInput extends StatefulWidget {
  final Future<bool> Function(String content, {String? imagePath}) onSend;
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
  static const int _maxImageBytes = 5 * 1024 * 1024;

  String? _selectedImagePath;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSend =>
      !widget.isSending &&
      !widget.isDisabled &&
      (_controller.text.trim().isNotEmpty || _selectedImagePath != null);

  bool get _showCounter =>
      _controller.text.length >= (_maxLength * _counterThreshold).round();

  bool get _isOverLimit => _controller.text.length > _maxLength;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    final fileSize = await File(picked.path).length();
    if (fileSize > _maxImageBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be under 5MB')),
      );
      return;
    }

    setState(() {
      _selectedImagePath = picked.path;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

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
            // Image preview
            if (_selectedImagePath != null) _buildImagePreview(theme),
            // Character counter
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
                // Image picker button
                Semantics(
                  label: 'Attach image',
                  button: true,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: widget.isDisabled || widget.isSending
                          ? null
                          : _pickImage,
                      icon: Icon(
                        Icons.camera_alt,
                        size: 22,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
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
                Semantics(
                  label: 'Send message',
                  button: true,
                  enabled: _canSend && !_isOverLimit,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed:
                          _canSend && !_isOverLimit ? _handleSend : null,
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_selectedImagePath!),
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: _removeImage,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: theme.colorScheme.onError,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final content = _controller.text.trim();
    final imagePath = _selectedImagePath;

    if (content.isEmpty && imagePath == null) return;
    if (content.length > _maxLength) return;

    final success = await widget.onSend(content, imagePath: imagePath);
    if (success && mounted) {
      _controller.clear();
      setState(() {
        _selectedImagePath = null;
      });
    }
  }
}
