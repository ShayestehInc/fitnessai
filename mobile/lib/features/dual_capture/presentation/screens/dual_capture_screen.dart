import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../widgets/camera_bubble.dart';
import '../widgets/recording_controls.dart';

/// Dual Capture screen — Loom-style recording (v6.5 §22).
///
/// Supports: camera only, screen + camera PiP, screen only.
/// Uses the `camera` package for live preview + video recording.
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

class _DualCaptureScreenState extends ConsumerState<DualCaptureScreen>
    with WidgetsBindingObserver {
  String _captureMode = 'front_only';
  bool _isRecording = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _useFrontCamera = true;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  String? _cameraError;

  static const _captureModes = [
    MapEntry('front_only', 'Camera Only'),
    MapEntry('screen_plus_front', 'Screen + Camera'),
    MapEntry('screen_only', 'Screen Only'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _cameraError = 'No cameras available');
        return;
      }

      final camera = _useFrontCamera
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Camera error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview or placeholder
            _buildCameraPreview(),

            // Top bar with close + mode selector
            _buildTopBar(),

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

  Widget _buildCameraPreview() {
    if (_captureMode == 'screen_only') {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.screen_share_rounded, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text('Screen recording mode',
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              SizedBox(height: 8),
              Text('Your screen will be captured',
                  style: TextStyle(color: Colors.white30, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_cameraError != null) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              Text(_cameraError!,
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _initCamera,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white38),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 1,
          height: _cameraController!.value.previewSize?.width ?? 1,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                if (_isRecording) {
                  _showDiscardConfirmation();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            if (!_isRecording)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _captureModes.map((mode) {
                          final isSelected = _captureMode == mode.key;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _captureMode = mode.key);
                              if (mode.key != 'screen_only') {
                                _initCamera();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white24
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                mode.value,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white54,
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
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_captureMode != 'screen_only' && _cameraController != null) {
      try {
        await _cameraController!.startVideoRecording();
      } catch (e) {
        if (mounted) {
          showAdaptiveToast(context,
              message: 'Failed to start recording: $e',
              type: ToastType.error);
        }
        return;
      }
    }

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
  }

  Future<void> _pauseRecording() async {
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      await _cameraController!.pauseVideoRecording();
    }
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    if (_cameraController != null && _cameraController!.value.isRecordingPaused) {
      await _cameraController!.resumeVideoRecording();
    }
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    XFile? videoFile;
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      videoFile = await _cameraController!.stopVideoRecording();
    }

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (videoFile != null && mounted) {
      showAdaptiveToast(context,
          message: 'Video saved: ${videoFile.name}',
          type: ToastType.success);
      // TODO: Upload to backend via video_message_service
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _discardRecording() async {
    _timer?.cancel();
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      await _cameraController!.stopVideoRecording();
    }
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _elapsedSeconds = 0;
    });
  }

  Future<void> _flipCamera() async {
    setState(() => _useFrontCamera = !_useFrontCamera);
    await _cameraController?.dispose();
    _cameraController = null;
    setState(() => _isCameraInitialized = false);
    await _initCamera();
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
