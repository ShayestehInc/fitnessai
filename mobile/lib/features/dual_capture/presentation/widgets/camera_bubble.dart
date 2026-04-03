import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Draggable, resizable camera preview bubble overlay (v6.5 §22).
/// Used in screen + camera PiP mode. Shows a live camera preview.
class CameraBubble extends StatefulWidget {
  final CameraController? cameraController;
  final double initialSize;
  final VoidCallback? onMinimizeChanged;

  const CameraBubble({
    super.key,
    this.cameraController,
    this.initialSize = 120,
    this.onMinimizeChanged,
  });

  @override
  State<CameraBubble> createState() => _CameraBubbleState();
}

class _CameraBubbleState extends State<CameraBubble> {
  late double _size;
  bool _minimized = false;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _size = widget.initialSize;
  }

  @override
  Widget build(BuildContext context) {
    if (_minimized) {
      return GestureDetector(
        onTap: () {
          setState(() => _minimized = false);
          widget.onMinimizeChanged?.call();
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38, width: 2),
          ),
          child: const Icon(Icons.videocam, color: Colors.white, size: 20),
        ),
      );
    }

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() => _offset += details.delta);
      },
      onDoubleTap: () {
        setState(() {
          _size = _size == widget.initialSize
              ? widget.initialSize * 1.5
              : widget.initialSize;
        });
      },
      onLongPress: () {
        setState(() => _minimized = true);
        widget.onMinimizeChanged?.call();
      },
      child: Transform.translate(
        offset: _offset,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(_size / 6),
            border: Border.all(color: Colors.white38, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_size / 6 - 2),
            child: Stack(
              children: [
                // Live camera preview or placeholder
                _buildPreview(),
                // Minimize hint
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.minimize_rounded,
                      color: Colors.white54,
                      size: 12,
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

  Widget _buildPreview() {
    final controller = widget.cameraController;
    if (controller != null && controller.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1,
            height: controller.value.previewSize?.width ?? 1,
            child: CameraPreview(controller),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white24,
          size: 40,
        ),
      ),
    );
  }
}
