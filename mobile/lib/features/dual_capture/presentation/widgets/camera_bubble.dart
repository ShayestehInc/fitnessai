import 'package:flutter/material.dart';

/// Draggable, resizable camera preview bubble overlay (v6.5 §22).
/// Used in screen + camera PiP mode.
class CameraBubble extends StatefulWidget {
  final double initialSize;

  const CameraBubble({super.key, this.initialSize = 120});

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
        onTap: () => setState(() => _minimized = false),
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
      onLongPress: () => setState(() => _minimized = true),
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
                // Camera preview placeholder
                Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white24,
                      size: 40,
                    ),
                  ),
                ),
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
}
