import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/community_feed_provider.dart';

/// Bottom sheet for composing a new text post with optional image.
class ComposePostSheet extends ConsumerStatefulWidget {
  const ComposePostSheet({super.key});

  @override
  ConsumerState<ComposePostSheet> createState() => _ComposePostSheetState();
}

class _ComposePostSheetState extends ConsumerState<ComposePostSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _isMarkdown = false;
  String? _imagePath;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Share with your community',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Toolbar row
          _buildToolbar(theme),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 1000,
            autofocus: true,
            decoration: InputDecoration(
              hintText: _isMarkdown
                  ? 'Write using **bold**, *italic*, etc.'
                  : 'What\'s on your mind?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
            ),
            onChanged: (_) => setState(() {}),
          ),
          // Image preview
          if (_imagePath != null) ...[
            const SizedBox(height: 8),
            _buildImagePreview(theme),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Row(
      children: [
        // Markdown toggle
        FilterChip(
          selected: _isMarkdown,
          label: const Text('Markdown'),
          avatar: Icon(
            Icons.text_format,
            size: 18,
            color: _isMarkdown
                ? theme.colorScheme.onPrimary
                : theme.iconTheme.color,
          ),
          onSelected: (val) => setState(() => _isMarkdown = val),
          selectedColor: theme.colorScheme.primary,
          labelStyle: TextStyle(
            color: _isMarkdown
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyMedium?.color,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        // Image picker
        ActionChip(
          label: Text(
            _imagePath != null ? 'Change Image' : 'Add Image',
            style: const TextStyle(fontSize: 12),
          ),
          avatar: const Icon(Icons.image_outlined, size: 18),
          onPressed: _pickImage,
        ),
      ],
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_imagePath!),
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _imagePath = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  bool get _canSubmit =>
      !_isSubmitting && _controller.text.trim().isNotEmpty;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success =
        await ref.read(communityFeedProvider.notifier).createPost(
              content: content,
              contentFormat: _isMarkdown ? 'markdown' : 'plain',
              imagePath: _imagePath,
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posted!'),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create post. Please try again.')),
      );
    }
  }
}
