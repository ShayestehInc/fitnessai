import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Full-screen shimmer skeleton matching the dashboard layout.
class DashboardShimmer extends StatefulWidget {
  const DashboardShimmer({super.key});

  @override
  State<DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<DashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(160, 22),
                      const SizedBox(height: 6),
                      _bar(100, 14),
                    ],
                  ),
                  const Spacer(),
                  _circle(36),
                ],
              ),
              const SizedBox(height: 20),
              // Calendar strip
              _bar(double.infinity, 72, radius: 12),
              const SizedBox(height: 24),
              // Workout cards
              _bar(120, 18),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: Row(
                  children: [
                    Expanded(child: _bar(double.infinity, 240, radius: 16)),
                    const SizedBox(width: 12),
                    Expanded(child: _bar(double.infinity, 240, radius: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Activity rings
              Center(child: _circle(160)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Center(child: _bar(60, 12))),
                  Expanded(child: Center(child: _bar(60, 12))),
                  Expanded(child: Center(child: _bar(60, 12))),
                ],
              ),
              const SizedBox(height: 24),
              // Health metrics
              Row(
                children: [
                  Expanded(child: _bar(double.infinity, 120, radius: 12)),
                  const SizedBox(width: 12),
                  Expanded(child: _bar(double.infinity, 120, radius: 12)),
                ],
              ),
              const SizedBox(height: 24),
              // Weight
              _bar(double.infinity, 80, radius: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _shimmerColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _circle(double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: _shimmerColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Color get _shimmerColor {
    final t = _controller.value;
    return Color.lerp(AppTheme.zinc800, AppTheme.zinc700, (0.5 + 0.5 * (t * 2 - 1).abs()).clamp(0.0, 1.0))!;
  }
}
