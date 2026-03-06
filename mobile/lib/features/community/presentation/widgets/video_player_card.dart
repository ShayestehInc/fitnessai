import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/post_video_model.dart';
import 'fullscreen_video_player.dart';

/// Inline video player card for community feed posts.
/// Shows thumbnail with play button overlay. Tap to play/pause.
/// Long-press or fullscreen icon for immersive playback.
class VideoPlayerCard extends StatefulWidget {
  final PostVideoModel video;

  const VideoPlayerCard({super.key, required this.video});

  @override
  State<VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<VideoPlayerCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    if (_controller != null) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.url),
    );

    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
      controller.addListener(_onPlayerStateChanged);
      await controller.play();
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      controller.dispose();
    }
  }

  void _onPlayerStateChanged() {
    if (!mounted || _controller == null) return;
    final playing = _controller!.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized) {
      _initializePlayer();
      return;
    }
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  void _openFullscreen() {
    if (_controller != null && _isInitialized) {
      _controller!.pause();
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullscreenVideoPlayer(videoUrl: widget.video.url),
      ),
    ).then((_) {
      // Resume playback when returning from fullscreen (if still mounted)
      if (mounted && _controller != null && _isInitialized) {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _isInitialized
            ? _controller!.value.aspectRatio
            : 16 / 9,
        child: GestureDetector(
          onTap: _togglePlayPause,
          onLongPress: _openFullscreen,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video or thumbnail
              if (_isInitialized && _controller != null)
                VideoPlayer(_controller!)
              else if (widget.video.thumbnailUrl != null)
                Image.network(
                  widget.video.thumbnailUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                )
              else
                _buildPlaceholder(theme),

              // Error overlay
              if (_hasError)
                _buildErrorOverlay(theme),

              // Play button overlay (when not playing)
              if (!_isPlaying && !_hasError)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

              // Duration badge (top-right, only before playback starts)
              if (!_isInitialized && widget.video.formattedDuration.isNotEmpty)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.video.formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // Fullscreen button (bottom-right, when playing)
              if (_isInitialized)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _openFullscreen,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.videocam_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(ThemeData theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _hasError = false;
                  _controller?.dispose();
                  _controller = null;
                  _isInitialized = false;
                });
                _initializePlayer();
              },
              child: Text(
                'Tap to retry',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
