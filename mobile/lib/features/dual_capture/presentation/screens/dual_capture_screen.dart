import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/camera_bubble.dart';
import '../widgets/recording_controls.dart';

/// Dual Capture screen — Loom-style recording (v6.5 §22).
///
/// Supports: screen only, camera only, screen + camera PiP.
/// Controls: record, pause, resume, stop, discard.
class DualCaptureScreen extends ConsumerStatefulWidget {
  final String? traineeId;
  final String? referencedObjectType;
  final String? referencedObjectId;

  const DualCaptureScreen({
    super.key,
    this.traineeId,
    this.referencedObjectType,
    this.referencedObjectId,
  });

  @override
  ConsumerState<DualCaptureScreen> createState() => _DualCaptureScreenState();
}

class _DualCaptureScreenState extends ConsumerState<DualCaptureScreen> {
  String _captureMode = 'front_only';
  bool _isRecording = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _useFrontCamera = true;

  static const _captureModes = [
    MapEntry('front_only', 'Camera Only'),
    MapEntry('screen_plus_front', 'Screen + Camera'),
    MapEntry('screen_only', 'Screen Only'),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview placeholder
            _buildCameraPreview(theme),

            // Top bar with close + mode selector
            _buildTopBar(theme),

            // Camera bubble (PiP mode)
            if (_captureMode == 'screen_plus_front' ||
                _captureMode == 'screen_plus_rear')
              const Positioned(
                bottom: 140,
                right: 16,
                child: CameraBubble(),
              ),

            // Bottom controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RecordingControls(
                isRecording: _isRecording,
                isPaused: _isPaused,
                elapsedSeconds: _elapsedSeconds,
                onRecord: _startRecording,
                onPause: _pauseRecording,
                onResume: _resumeRecording,
                onStop: _stopRecording,
                onDiscard: _discardRecording,
                onFlipCamera: _flipCamera,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(ThemeData theme) {
    // In production: use CameraPreview from the `camera` package
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _captureMode == 'screen_only'
                  ? Icons.screen_share_rounded
                  : Icons.videocam_rounded,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording
                  ? (_isPaused ? 'Paused' : 'Recording...')
                  : 'Ready to record',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _captureMode == 'screen_only'
                  ? 'Screen recording mode'
                  : _useFrontCamera
                      ? 'Front camera'
                      : 'Rear camera',
              style: const TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                if (_isRecording) {
                  _showDiscardConfirmation();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            // Mode selector (centered, flexible)
            if (!_isRecording)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _captureModes.map((mode) {
                          final isSelected = _captureMode == mode.key;
                          return GestureDetector(
                            onTap: () => setState(() => _captureMode = mode.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white24 : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                mode.value,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: 48), // Balance close button
          ],
        ),
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() => _elapsedSeconds++);
      }
    });
    // TODO: Start actual camera/screen recording via platform channels
  }

  void _pauseRecording() {
    setState(() => _isPaused = true);
    // TODO: Pause recording
  }

  void _resumeRecording() {
    setState(() => _isPaused = false);
    // TODO: Resume recording
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
    // TODO: Stop recording, save file, upload to backend
    // For now, pop back
    Navigator.of(context).pop();
  }

  void _discardRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _elapsedSeconds = 0;
    });
    // TODO: Discard recording file
  }

  void _flipCamera() {
    setState(() => _useFrontCamera = !_useFrontCamera);
    // TODO: Switch camera source
  }

  void _showDiscardConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Recording?'),
        content: const Text('Your recording will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Recording'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _discardRecording();
              Navigator.of(context).pop();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
