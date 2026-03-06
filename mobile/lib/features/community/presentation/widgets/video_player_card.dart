import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/post_video_model.dart';
import 'fullscreen_video_player.dart';
import '../../../../core/l10n/l10n_extension.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    if (_controller != null || _isLoading) return;

    setState(() => _isLoading = true);

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
        _isLoading = false;
      });
      controller.addListener(_onPlayerStateChanged);
      await controller.setVolume(0); // Start muted in feed
      await controller.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
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

    return Semantics(
      label: context.l10n.communityVideoAttachmentTapToPlayLongPressForFullscree,
      child: ClipRRect(
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

              // Loading spinner (while video initializes)
              if (_isLoading && !_hasError)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Play button overlay (when not playing and not loading)
              if (!_isPlaying && !_hasError && !_isLoading)
                Semantics(
                  label: context.l10n.communityPlayVideo,
                  button: true,
                  child: Container(
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

              // Mute indicator (bottom-left, when playing muted)
              if (_isInitialized && _controller != null && _controller!.value.volume == 0)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Semantics(
                    label: context.l10n.communityUnmuteVideo,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _controller!.setVolume(1);
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.volume_off,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Fullscreen button (bottom-right, when playing)
              if (_isInitialized)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Semantics(
                    label: context.l10n.communityOpenFullscreenVideo,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openFullscreen,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white70,
              size: 32,
            ),
            const SizedBox(height: 4),
            const Text(
              'Video failed to load',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _hasError = false;
                  _controller?.dispose();
                  _controller = null;
                  _isInitialized = false;
                });
                _initializePlayer();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tap to retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
