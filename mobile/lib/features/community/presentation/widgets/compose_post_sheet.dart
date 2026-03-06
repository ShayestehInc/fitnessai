import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/space_model.dart';
import '../providers/community_feed_provider.dart';
import '../providers/space_provider.dart';

/// Bottom sheet for composing a new text post with multi-image and space selector.
class ComposePostSheet extends ConsumerStatefulWidget {
  final int? initialSpaceId;

  const ComposePostSheet({super.key, this.initialSpaceId});

  @override
  ConsumerState<ComposePostSheet> createState() => _ComposePostSheetState();
}

class _ComposePostSheetState extends ConsumerState<ComposePostSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _isMarkdown = false;
  final List<String> _imagePaths = [];
  int? _selectedSpaceId;

  static const int _maxImages = 10;
  static const int _maxImageSizeBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _selectedSpaceId = widget.initialSpaceId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final spacesState = ref.watch(spacesProvider);

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
          // Space picker (if spaces exist)
          if (spacesState.spaces.isNotEmpty) ...[
            _buildSpacePicker(theme, spacesState.spaces),
            const SizedBox(height: 8),
          ],
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
          // Image previews
          if (_imagePaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildImagePreviews(theme),
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
                  ? AdaptiveSpinner.small()
                  : const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacePicker(ThemeData theme, List<SpaceModel> spaces) {
    return DropdownButtonFormField<int?>(
      value: _selectedSpaceId,
      decoration: InputDecoration(
        labelText: 'Post to',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('General feed'),
        ),
        ...spaces.map((s) => DropdownMenuItem<int?>(
              value: s.id,
              child: Text('${s.emoji} ${s.name}'),
            )),
      ],
      onChanged: (value) => setState(() => _selectedSpaceId = value),
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
            _imagePaths.isNotEmpty
                ? '${_imagePaths.length}/$_maxImages'
                : 'Add Images',
            style: const TextStyle(fontSize: 12),
          ),
          avatar: const Icon(Icons.image_outlined, size: 18),
          onPressed: _imagePaths.length < _maxImages ? _pickImages : null,
        ),
      ],
    );
  }

  Widget _buildImagePreviews(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _imagePaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_imagePaths[index]),
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _imagePaths.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool get _canSubmit =>
      !_isSubmitting && _controller.text.trim().isNotEmpty;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remaining = _maxImages - _imagePaths.length;
    if (remaining <= 0) return;

    final picked = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (picked.isEmpty || !mounted) return;

    final toAdd = picked.take(remaining);
    for (final file in toAdd) {
      final fileSize = await File(file.path).length();
      if (fileSize > _maxImageSizeBytes) {
        if (!mounted) return;
        showAdaptiveToast(
          context,
          message: 'Image "${file.name}" is over 5MB and was skipped.',
          type: ToastType.error,
        );
        continue;
      }
      if (mounted) {
        setState(() => _imagePaths.add(file.path));
      }
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
              imagePaths: _imagePaths,
              spaceId: _selectedSpaceId,
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      showAdaptiveToast(context,
          message: 'Posted!', type: ToastType.success);
    } else {
      showAdaptiveToast(context,
          message: 'Failed to create post. Please try again.',
          type: ToastType.error);
    }
  }
}
