import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Fullscreen video player with native controls.
/// Supports landscape, seek bar, play/pause, and mute toggle.
class FullscreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullscreenVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      _controller.addListener(_onStateChanged);
      await _controller.play();
      _startControlsTimer();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video
            Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : _hasError
                      ? _buildError()
                      : const CircularProgressIndicator(color: Colors.white),
            ),

            // Controls overlay
            if (_showControls && _isInitialized)
              _buildControls(context),

            // Close button (always visible)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: Semantics(
                label: context.l10n.communityCloseFullscreenVideo,
                button: true,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  tooltip: context.l10n.commonClose,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final isPlaying = _controller.value.isPlaying;

    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seek bar
            Semantics(
              label: context.l10n.communityVideoSeekBar,
              slider: true,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0,
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds: (value * duration.inMilliseconds).round(),
                  );
                  _controller.seekTo(newPosition);
                },
              ),
            ),
            ),

            // Controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Time
                Text(
                  '${_formatDuration(position)} / ${_formatDuration(duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),

                // Play/Pause
                IconButton(
                  onPressed: () {
                    if (isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                      _startControlsTimer();
                    }
                  },
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                // Mute toggle
                IconButton(
                  onPressed: () {
                    final vol = _controller.value.volume;
                    _controller.setVolume(vol > 0 ? 0 : 1);
                  },
                  tooltip: _controller.value.volume > 0 ? 'Mute' : 'Unmute',
                  icon: Icon(
                    _controller.value.volume > 0
                        ? Icons.volume_up
                        : Icons.volume_off,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.white54, size: 48),
        const SizedBox(height: 8),
        const Text(
          'Failed to load video',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            _controller.dispose();
            _controller = VideoPlayerController.networkUrl(
              Uri.parse(widget.videoUrl),
            );
            setState(() {
              _hasError = false;
              _isInitialized = false;
            });
            _initialize();
          },
          child: Text(context.l10n.commonRetry, style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
