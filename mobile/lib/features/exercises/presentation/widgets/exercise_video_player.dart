import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen video player for exercise demo videos.
/// Shows a play/pause overlay and a seek bar.
class ExerciseVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String exerciseName;

  const ExerciseVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.exerciseName,
  });

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) {
        setState(() => _isInitialized = true);
        await _controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load video',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_controller.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: theme.colorScheme.primary,
                bufferedColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tappable thumbnail that opens the video player in a dialog.
class ExerciseVideoThumbnail extends StatelessWidget {
  final String? videoUrl;
  final String exerciseName;
  final double size;

  const ExerciseVideoThumbnail({
    super.key,
    required this.videoUrl,
    required this.exerciseName,
    this.size = 48,
  });

  bool get _hasValidUrl {
    if (videoUrl == null || videoUrl!.isEmpty) return false;
    final uri = Uri.tryParse(videoUrl!);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidUrl) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showVideoDialog(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.play_circle_outline,
          size: size * 0.6,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showVideoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(exerciseName),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            ExerciseVideoPlayer(
              videoUrl: videoUrl!,
              exerciseName: exerciseName,
            ),
          ],
        ),
      ),
    );
  }
}
