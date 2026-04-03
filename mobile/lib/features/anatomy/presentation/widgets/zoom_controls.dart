import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const ZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(icon: Icons.add, onTap: onZoomIn),
          _divider(),
          _ZoomButton(icon: Icons.remove, onTap: onZoomOut),
          _divider(),
          _ZoomButton(icon: Icons.crop_free, onTap: onReset),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      width: 28,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 20,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
