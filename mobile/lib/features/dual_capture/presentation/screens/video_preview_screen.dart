import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/video_message_provider.dart';

/// Preview screen shown after recording — play back, send or discard.
class VideoPreviewScreen extends ConsumerStatefulWidget {
  final String videoPath;
  final int durationSeconds;
  final String captureMode;

  const VideoPreviewScreen({
    super.key,
    required this.videoPath,
    required this.durationSeconds,
    required this.captureMode,
  });

  @override
  ConsumerState<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends ConsumerState<VideoPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final file = File(widget.videoPath);

    // Screen recordings may not be fully flushed to disk immediately —
    // wait briefly and retry if the file doesn't exist yet.
    if (!file.existsSync()) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!file.existsSync()) {
        setState(
            () => _videoError = 'Video file not found:\n${widget.videoPath}');
        return;
      }
    }

    // Wait for the file to have content (screen recording writes may lag).
    for (var i = 0; i < 5; i++) {
      if (file.lengthSync() > 0) break;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _videoController = controller;
      controller.setLooping(true);
      await controller.play();
      setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        setState(() => _videoError = 'Could not load video: $e');
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(recordingSessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video preview
            Center(child: _buildVideoPreview()),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed:
                          session.isUploading ? null : () => _discardVideo(),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(widget.durationSeconds),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _modeLabel(widget.captureMode),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Play/pause overlay
            if (_isInitialized && _videoController != null)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: AnimatedOpacity(
                    opacity:
                        _videoController!.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom action bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    // Discard
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            session.isUploading ? null : () => _discardVideo(),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Discard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Send
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: session.isUploading ? null : _uploadVideo,
                        icon: session.isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                            session.isUploading ? 'Uploading...' : 'Send'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error banner
            if (session.error != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 100,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session.error!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Video recorded successfully',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _videoError!,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _formatDuration(widget.durationSeconds),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You can still send this video.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      );
    }

    if (!_isInitialized) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'Loading preview...',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  Future<void> _uploadVideo() async {
    _videoController?.pause();

    final notifier = ref.read(recordingSessionProvider.notifier);
    final success = await notifier.uploadVideo(
      filePath: widget.videoPath,
      durationSeconds: widget.durationSeconds.toDouble(),
    );

    if (!mounted) return;

    if (success) {
      showAdaptiveToast(
        context,
        message: 'Video sent successfully',
        type: ToastType.success,
      );
      // Pop both preview and capture screens
      Navigator.of(context)
        ..pop()
        ..pop();
    }
  }

  void _discardVideo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Video?'),
        content: const Text('This recording will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(recordingSessionProvider.notifier).discardSession();
              // Delete the local file
              final file = File(widget.videoPath);
              if (file.existsSync()) file.deleteSync();
              // Pop both screens
              Navigator.of(context)
                ..pop()
                ..pop();
            },
            child:
                const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'screen_only':
        return 'Screen Only';
      case 'front_only':
        return 'Camera';
      case 'rear_only':
        return 'Rear Camera';
      case 'screen_plus_front':
        return 'Screen + Cam';
      case 'screen_plus_rear':
        return 'Screen + Rear';
      default:
        return mode;
    }
  }
}
