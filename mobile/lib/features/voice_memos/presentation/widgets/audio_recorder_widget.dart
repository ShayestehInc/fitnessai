import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Audio recorder widget with mic button, recording indicator, and duration.
///
/// Uses a placeholder recording approach that creates a temporary file.
/// Wire up actual recording with the `record` package when ready.
class AudioRecorderWidget extends StatefulWidget {
  final ValueChanged<File> onRecordingComplete;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording) ...[
          _buildDurationDisplay(theme),
          const SizedBox(height: 16),
          _buildWaveformPlaceholder(theme),
          const SizedBox(height: 24),
        ],
        _buildRecordButton(theme),
        const SizedBox(height: 12),
        Text(
          _isRecording ? 'Tap to stop' : 'Tap to record',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDurationDisplay(ThemeData theme) {
    final minutes = _elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$minutes:$seconds',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformPlaceholder(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (index) {
          final heightFactor = 0.3 +
              (0.7 *
                  ((index + _elapsed.inSeconds) % 5 / 5.0).abs());
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 3,
              height: 48 * heightFactor,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: 0.4 + (heightFactor * 0.6),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecordButton(ThemeData theme) {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: ScaleTransition(
        scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isRecording
                ? const Color(0xFFEF4444)
                : theme.colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: (_isRecording
                        ? const Color(0xFFEF4444)
                        : theme.colorScheme.primary)
                    .withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _elapsed = Duration.zero;
    });

    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    setState(() => _isRecording = false);

    // Create a placeholder file to represent the recording.
    // Replace with actual audio data from the `record` package.
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFile = File('${tempDir.path}/voice_memo_$timestamp.m4a');
    await tempFile.writeAsBytes([]);

    widget.onRecordingComplete(tempFile);
  }
}
