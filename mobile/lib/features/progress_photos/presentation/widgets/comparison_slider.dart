import 'package:flutter/material.dart';

/// An interactive before/after comparison slider that overlays two images.
///
/// The user drags the divider handle left/right to reveal more of one image
/// versus the other.
class ComparisonSlider extends StatefulWidget {
  final String? beforeUrl;
  final String? afterUrl;
  final String beforeLabel;
  final String afterLabel;

  const ComparisonSlider({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
  });

  @override
  State<ComparisonSlider> createState() => _ComparisonSliderState();
}

class _ComparisonSliderState extends State<ComparisonSlider> {
  double _sliderPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _sliderPosition =
                  (details.localPosition.dx / width).clamp(0.05, 0.95);
            });
          },
          child: Stack(
            children: [
              // After image (full width, behind)
              Positioned.fill(
                child: _buildImage(
                  widget.afterUrl,
                  theme,
                  BoxFit.cover,
                ),
              ),

              // Before image (clipped to slider position)
              Positioned.fill(
                child: ClipRect(
                  clipper: _LeftClipper(_sliderPosition * width),
                  child: _buildImage(
                    widget.beforeUrl,
                    theme,
                    BoxFit.cover,
                  ),
                ),
              ),

              // Divider line
              Positioned(
                left: _sliderPosition * width - 1.5,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Colors.white,
                ),
              ),

              // Drag handle
              Positioned(
                left: _sliderPosition * width - 20,
                top: height / 2 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
              ),

              // Before label
              Positioned(
                top: 12,
                left: 12,
                child: _buildLabel(widget.beforeLabel),
              ),

              // After label
              Positioned(
                top: 12,
                right: 12,
                child: _buildLabel(widget.afterLabel),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String? url, ThemeData theme, BoxFit fit) {
    if (url == null || url.isEmpty) {
      return Container(
        color: theme.cardColor,
        child: Center(
          child: Icon(
            Icons.photo_outlined,
            size: 48,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: theme.cardColor,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Custom clipper that clips everything to the right of [splitX].
class _LeftClipper extends CustomClipper<Rect> {
  final double splitX;

  _LeftClipper(this.splitX);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, splitX, size.height);
  }

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) {
    return oldClipper.splitX != splitX;
  }
}
