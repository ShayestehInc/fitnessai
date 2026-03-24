import 'package:flutter/material.dart';

/// Floating button that appears on the session runner to report pain.
class PainToggleButton extends StatelessWidget {
  final VoidCallback onTap;

  const PainToggleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'pain_toggle',
      onPressed: onTap,
      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.9),
      child: const Icon(
        Icons.healing_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
