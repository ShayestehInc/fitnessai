import 'package:flutter/material.dart';

/// Recording controls bar — record/pause/resume/stop/discard (v6.5 §22).
class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final int elapsedSeconds;
  final VoidCallback onRecord;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onDiscard;
  final VoidCallback onFlipCamera;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.elapsedSeconds,
    required this.onRecord,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onDiscard,
    required this.onFlipCamera,
  });

  String get _formattedTime {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer
          if (isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isPaused ? Colors.yellow : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (isPaused) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'PAUSED',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Flip camera
              if (!isRecording || isPaused)
                _ControlButton(
                  icon: Icons.flip_camera_ios_rounded,
                  label: 'Flip',
                  onTap: onFlipCamera,
                )
              else
                const SizedBox(width: 64),

              // Main record button
              if (!isRecording)
                _RecordButton(onTap: onRecord)
              else if (isPaused)
                _RecordButton(onTap: onResume, isResume: true)
              else
                _PauseButton(onTap: onPause),

              // Stop / Discard
              if (isRecording)
                _ControlButton(
                  icon: Icons.stop_rounded,
                  label: 'Done',
                  color: Colors.white,
                  onTap: onStop,
                )
              else
                const SizedBox(width: 64),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isResume;

  const _RecordButton({required this.onTap, this.isResume = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isResume ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: isResume
                ? const Icon(Icons.play_arrow, color: Colors.white, size: 32)
                : null,
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PauseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: const Center(
          child: Icon(Icons.pause, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.color = Colors.white70,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
