import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LayerControls extends StatelessWidget {
  final String currentLayer;
  final ValueChanged<String> onLayerChanged;

  const LayerControls({
    super.key,
    required this.currentLayer,
    required this.onLayerChanged,
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
          _LayerButton(
            icon: Icons.accessibility_new,
            label: 'Muscles',
            isActive: currentLayer == 'muscles',
            onTap: () => _select('muscles'),
          ),
          _divider(),
          _LayerButton(
            icon: Icons.remove_red_eye_outlined,
            label: 'X-Ray',
            isActive: currentLayer == 'xray',
            onTap: () => _select('xray'),
          ),
          _divider(),
          _LayerButton(
            icon: Icons.schema_outlined,
            label: 'Skeleton',
            isActive: currentLayer == 'skeleton',
            onTap: () => _select('skeleton'),
          ),
        ],
      ),
    );
  }

  void _select(String layer) {
    HapticFeedback.selectionClick();
    onLayerChanged(layer);
  }

  Widget _divider() {
    return Container(
      height: 1,
      width: 36,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _LayerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LayerButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF6366F1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isActive
                    ? activeColor
                    : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
