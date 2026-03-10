import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/video_analysis_provider.dart';
import 'analysis_detail_screen.dart';

/// Screen for uploading a video for AI form analysis.
class VideoUploadScreen extends ConsumerStatefulWidget {
  final int? exerciseId;

  const VideoUploadScreen({super.key, this.exerciseId});

  @override
  ConsumerState<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends ConsumerState<VideoUploadScreen> {
  final _imagePicker = ImagePicker();
  File? _selectedVideo;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Video Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoPicker(theme),
            const SizedBox(height: 24),
            _buildInstructions(theme),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading || _selectedVideo == null
                    ? null
                    : _uploadVideo,
                child: _isUploading
                    ? const AdaptiveSpinner.small()
                    : const Text('Analyze Video'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPicker(ThemeData theme) {
    return GestureDetector(
      onTap: _showVideoSourceSheet,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor,
            width: _selectedVideo == null ? 2 : 0,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: _selectedVideo != null
            ? Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Video selected',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedVideo!.path.split('/').last,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _selectedVideo = null);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_call_outlined,
                    size: 48,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to select a video',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Camera or Gallery',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips for best results',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip(theme, 'Record from a side or 45-degree angle'),
          _buildTip(theme, 'Include 3-5 complete reps'),
          _buildTip(theme, 'Ensure good lighting'),
          _buildTip(theme, 'Keep the camera steady'),
        ],
      ),
    );
  }

  Widget _buildTip(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022  ',
            style: theme.textTheme.bodySmall,
          ),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  void _showVideoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.of(context).pop();
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickVideo(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked != null) {
        setState(() => _selectedVideo = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      showAdaptiveToast(
        context,
        message: 'Failed to pick video: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) return;

    setState(() => _isUploading = true);

    final result =
        await ref.read(uploadVideoAnalysisProvider.notifier).upload(
              filePath: _selectedVideo!.path,
              exerciseId: widget.exerciseId,
            );

    if (!mounted) return;

    if (result != null) {
      showAdaptiveToast(
        context,
        message: 'Video uploaded for analysis!',
        type: ToastType.success,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnalysisDetailScreen(analysisId: result.id),
        ),
      );
    } else {
      setState(() => _isUploading = false);
      showAdaptiveToast(
        context,
        message: 'Failed to upload video. Please try again.',
        type: ToastType.error,
      );
    }
  }
}
