import 'dart:async';
import 'package:flutter/material.dart';

/// Compact inline countdown timer for micro-rests (3-20 seconds).
/// Used in myo-reps, rest-pause, cluster sets, and drop sets.
class MicroRestTimer extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onComplete;
  final Color? color;

  const MicroRestTimer({
    super.key,
    required this.durationSeconds,
    required this.onComplete,
    this.color,
  });

  @override
  State<MicroRestTimer> createState() => _MicroRestTimerState();
}

class _MicroRestTimerState extends State<MicroRestTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..forward();

    _completeTimer = Timer(
      Duration(seconds: widget.durationSeconds),
      () {
        if (mounted) widget.onComplete();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.tertiary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final remaining = (widget.durationSeconds * (1 - _controller.value)).ceil();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: 1 - _controller.value,
                  strokeWidth: 3,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${remaining}s',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  _completeTimer?.cancel();
                  widget.onComplete();
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
