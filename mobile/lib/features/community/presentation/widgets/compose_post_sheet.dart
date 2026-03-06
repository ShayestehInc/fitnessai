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
  double _uploadProgress = 0;
  final List<String> _imagePaths = [];
  final List<String> _videoPaths = [];
  int? _selectedSpaceId;

  static const int _maxImages = 10;
  static const int _maxImageSizeBytes = 5 * 1024 * 1024;
  static const int _maxVideos = 3;
  static const int _maxVideoSizeBytes = 50 * 1024 * 1024;

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
          // Video previews
          if (_videoPaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildVideoPreviews(theme),
          ],
          // Upload progress
          if (_isSubmitting) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              backgroundColor: theme.dividerColor,
            ),
            const SizedBox(height: 4),
            Text(
              _uploadProgress > 0
                  ? '${(_uploadProgress * 100).toInt()}% uploaded'
                  : 'Preparing upload...',
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
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
                : 'Images',
            style: const TextStyle(fontSize: 12),
          ),
          avatar: const Icon(Icons.image_outlined, size: 18),
          onPressed: _imagePaths.length < _maxImages ? _pickImages : null,
        ),
        const SizedBox(width: 8),
        // Video picker
        ActionChip(
          label: Text(
            _videoPaths.isNotEmpty
                ? '${_videoPaths.length}/$_maxVideos'
                : 'Video',
            style: const TextStyle(fontSize: 12),
          ),
          avatar: const Icon(Icons.videocam_outlined, size: 18),
          onPressed: _videoPaths.length < _maxVideos ? _pickVideo : null,
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
                top: 0,
                right: 0,
                child: Semantics(
                  label: 'Remove image ${index + 1}',
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _imagePaths.removeAt(index)),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
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
      !_isSubmitting &&
      (_controller.text.trim().isNotEmpty ||
          _imagePaths.isNotEmpty ||
          _videoPaths.isNotEmpty);

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

  Widget _buildVideoPreviews(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _videoPaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = _videoPaths[index];
          return FutureBuilder<int>(
            future: File(path).length(),
            builder: (context, snapshot) {
              final sizeMb = snapshot.hasData
                  ? (snapshot.data! / (1024 * 1024)).toStringAsFixed(1)
                  : '...';
              return Stack(
                children: [
                  Container(
                    height: 80,
                    width: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam,
                          size: 28,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sizeMb}MB',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Video badge
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'VIDEO',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Semantics(
                      label: 'Remove video ${index + 1}',
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            setState(() => _videoPaths.removeAt(index)),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final remaining = _maxVideos - _videoPaths.length;
    if (remaining <= 0) return;

    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (picked == null || !mounted) return;

    // Validate extension
    final ext = picked.path.split('.').last.toLowerCase();
    const allowedExts = {'mp4', 'm4v', 'mov', 'webm'};
    if (!allowedExts.contains(ext)) {
      if (!mounted) return;
      showAdaptiveToast(
        context,
        message: 'Unsupported format. Use MP4, MOV, or WebM.',
        type: ToastType.error,
      );
      return;
    }

    final fileSize = await File(picked.path).length();
    if (fileSize == 0) {
      if (!mounted) return;
      showAdaptiveToast(
        context,
        message: 'Video file is empty.',
        type: ToastType.error,
      );
      return;
    }
    if (fileSize > _maxVideoSizeBytes) {
      if (!mounted) return;
      showAdaptiveToast(
        context,
        message: 'Video must be under 50MB.',
        type: ToastType.error,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _videoPaths.add(picked.path));
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _imagePaths.isEmpty && _videoPaths.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
    });

    final success =
        await ref.read(communityFeedProvider.notifier).createPost(
              content: content,
              contentFormat: _isMarkdown ? 'markdown' : 'plain',
              imagePaths: _imagePaths,
              videoPaths: _videoPaths,
              spaceId: _selectedSpaceId,
              onUploadProgress: (sent, total) {
                if (total > 0 && mounted) {
                  setState(() => _uploadProgress = sent / total);
                }
              },
            );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _uploadProgress = 0;
    });

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
