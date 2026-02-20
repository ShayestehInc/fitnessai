import 'package:flutter/material.dart';

/// Bottom sheet for editing a message.
///
/// Shows a TextFormField pre-filled with the message content,
/// a character counter, and Save/Cancel buttons.
class EditMessageSheet extends StatefulWidget {
  final String initialContent;
  final void Function(String newContent) onSave;
  final VoidCallback onCancel;

  const EditMessageSheet({
    super.key,
    required this.initialContent,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<EditMessageSheet> createState() => _EditMessageSheetState();
}

class _EditMessageSheetState extends State<EditMessageSheet> {
  late final TextEditingController _controller;
  static const int _maxLength = 2000;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave {
    final text = _controller.text.trim();
    return text.isNotEmpty &&
        text != widget.initialContent &&
        text.length <= _maxLength;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Edit message',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller,
            maxLength: _maxLength,
            maxLines: 5,
            minLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Edit your message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_controller.text.length}/$_maxLength',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _controller.text.length > _maxLength
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _canSave
                    ? () => widget.onSave(_controller.text.trim())
                    : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
