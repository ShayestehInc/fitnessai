import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';

import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/video_message_provider.dart';
import '../widgets/camera_bubble.dart';
import '../widgets/recording_controls.dart';
import 'video_preview_screen.dart';

/// Dual Capture screen — Loom-style recording (v6.5 §22).
///
/// Supports three modes:
/// - Camera Only: full-screen camera recording via `camera` package
/// - Screen + Camera: screen recording (ReplayKit/MediaProjection) with
///   camera PiP bubble overlay. The screen recording captures both the
///   screen content and the camera bubble.
/// - Screen Only: screen recording without camera overlay
///
/// After recording, navigates to [VideoPreviewScreen] for review + upload.
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

  /// Whether screen recording is active (Screen Only or Screen + Camera).
  bool _isScreenRecording = false;

  static const _captureModes = [
    MapEntry('front_only', 'Camera Only'),
    MapEntry('screen_plus_front', 'Screen + Camera'),
    MapEntry('screen_only', 'Screen Only'),
  ];

  /// Whether the current mode needs a camera.
  bool get _needsCamera => _captureMode != 'screen_only';

  /// Whether the current mode uses screen recording.
  bool get _needsScreenRecording => _captureMode != 'front_only';

  /// Whether to show the camera as a PiP bubble (screen + camera mode).
  bool get _isPipMode =>
      _captureMode == 'screen_plus_front' ||
      _captureMode == 'screen_plus_rear';

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
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
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

      final oldController = _cameraController;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      await oldController?.dispose();

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
    final session = ref.watch(recordingSessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main view: full-screen camera or screen recording info
            _buildMainView(),

            // Top bar with close + mode selector
            _buildTopBar(session),

            // Camera PiP bubble (screen + camera mode)
            if (_isPipMode)
              Positioned(
                bottom: 140,
                right: 16,
                child: CameraBubble(
                  cameraController:
                      _isCameraInitialized ? _cameraController : null,
                ),
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
                onFlipCamera: _needsCamera ? _flipCamera : () {},
              ),
            ),

            // Starting session indicator
            if (session.isStarting)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Starting recording...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Main area: full-screen camera preview or screen-recording info.
  Widget _buildMainView() {
    // Screen-only mode
    if (_captureMode == 'screen_only') {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isRecording
                    ? Icons.fiber_manual_record
                    : Icons.screen_share_rounded,
                size: 64,
                color: _isRecording ? Colors.red.withValues(alpha: 0.6) : Colors.white24,
              ),
              const SizedBox(height: 16),
              Text(
                _isRecording
                    ? 'Recording your screen...'
                    : 'Screen recording mode',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _isRecording
                    ? 'Everything on screen is being captured.\nTap Done when finished.'
                    : 'Your screen will be recorded.\nTap the record button to start.',
                style: const TextStyle(color: Colors.white30, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // PiP mode (screen + camera): camera is in the bubble
    if (_isPipMode) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isRecording
                    ? Icons.fiber_manual_record
                    : Icons.screen_share_rounded,
                size: 64,
                color: _isRecording ? Colors.red.withValues(alpha: 0.6) : Colors.white24,
              ),
              const SizedBox(height: 16),
              Text(
                _isRecording
                    ? 'Recording screen + camera...'
                    : 'Screen + Camera mode',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _isRecording
                    ? 'Screen and camera are being recorded.\nThe camera bubble is captured in the recording.'
                    : 'Camera preview is in the bubble.\nTap record to start.',
                style: const TextStyle(color: Colors.white30, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Camera-only mode: full screen preview
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

  Widget _buildTopBar(RecordingSessionState session) {
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
                            onTap: () => _switchMode(mode.key),
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

  void _switchMode(String mode) {
    setState(() => _captureMode = mode);

    if (mode == 'screen_plus_front') {
      _useFrontCamera = true;
    }

    if (mode != 'screen_only') {
      _initCamera();
    }
  }

  Future<void> _startRecording() async {
    // Start backend session
    final notifier = ref.read(recordingSessionProvider.notifier);
    final assetId = await notifier.startSession(
      captureMode: _captureMode,
      traineeId:
          widget.traineeId != null ? int.tryParse(widget.traineeId!) : null,
    );

    if (assetId == null) {
      if (mounted) {
        final error = ref.read(recordingSessionProvider).error;
        showAdaptiveToast(context,
            message: error ?? 'Failed to start session',
            type: ToastType.error);
      }
      return;
    }

    // Start screen recording for screen modes
    if (_needsScreenRecording) {
      try {
        final started = await FlutterScreenRecording.startRecordScreenAndAudio(
          'dual_capture_${DateTime.now().millisecondsSinceEpoch}',
          titleNotification: 'FitnessAI Recording',
          messageNotification: 'Screen recording in progress',
        );
        if (!started) {
          if (mounted) {
            showAdaptiveToast(context,
                message: 'Screen recording permission denied',
                type: ToastType.error);
          }
          return;
        }
        _isScreenRecording = true;
      } catch (e) {
        if (mounted) {
          showAdaptiveToast(context,
              message: 'Failed to start screen recording: $e',
              type: ToastType.error);
        }
        return;
      }
    }

    // Start camera recording for camera-only mode
    if (_captureMode == 'front_only' && _cameraController != null) {
      try {
        await _cameraController!.startVideoRecording();
      } catch (e) {
        // Stop screen recording if it was started
        if (_isScreenRecording) {
          await FlutterScreenRecording.stopRecordScreen;
          _isScreenRecording = false;
        }
        if (mounted) {
          showAdaptiveToast(context,
              message: 'Failed to start camera: $e',
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
    // Camera pause (only in camera-only mode)
    if (_captureMode == 'front_only' &&
        _cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      await _cameraController!.pauseVideoRecording();
    }
    // Note: screen recording does not support pause — timer pauses but
    // the screen capture continues. This is a platform limitation.
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    if (_captureMode == 'front_only' &&
        _cameraController != null &&
        _cameraController!.value.isRecordingPaused) {
      await _cameraController!.resumeVideoRecording();
    }
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    String? videoPath;

    // Stop screen recording (Screen Only or Screen + Camera)
    if (_isScreenRecording) {
      try {
        videoPath = await FlutterScreenRecording.stopRecordScreen;
        _isScreenRecording = false;
      } catch (e) {
        if (mounted) {
          showAdaptiveToast(context,
              message: 'Failed to stop screen recording: $e',
              type: ToastType.error);
        }
      }
    }

    // Stop camera recording (Camera Only mode)
    if (_captureMode == 'front_only' &&
        _cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      final cameraFile = await _cameraController!.stopVideoRecording();
      videoPath = cameraFile.path;
    }

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (videoPath != null && videoPath.isNotEmpty && mounted) {
      // Navigate to preview screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPreviewScreen(
            videoPath: videoPath!,
            durationSeconds: _elapsedSeconds,
            captureMode: _captureMode,
          ),
        ),
      );

      // Reset for new recording
      if (mounted) {
        ref.read(recordingSessionProvider.notifier).reset();
        setState(() => _elapsedSeconds = 0);
      }
    } else if (mounted) {
      showAdaptiveToast(context,
          message: 'No video was recorded', type: ToastType.warning);
    }
  }

  Future<void> _discardRecording() async {
    _timer?.cancel();

    // Stop screen recording if active
    if (_isScreenRecording) {
      try {
        await FlutterScreenRecording.stopRecordScreen;
        _isScreenRecording = false;
      } catch (_) {}
    }

    // Stop camera recording if active
    if (_cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      await _cameraController!.stopVideoRecording();
    }

    ref.read(recordingSessionProvider.notifier).discardSession();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _elapsedSeconds = 0;
    });
  }

  Future<void> _flipCamera() async {
    if (!_needsCamera) return;

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
            child:
                const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
