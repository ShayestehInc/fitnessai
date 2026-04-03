import 'package:flutter/material.dart';

import 'body_map_widget.dart';

/// Non-interactive compact 3D body map for embedding in cards.
class MiniBodyMapWidget extends StatelessWidget {
  final BodyMapView view;
  final Map<String, double> muscleIntensities;
  final Map<String, Color>? highlightedMuscles;
  final double height;

  const MiniBodyMapWidget({
    super.key,
    required this.view,
    this.muscleIntensities = const {},
    this.highlightedMuscles,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: BodyMapWidget(
        view: view,
        muscleIntensities: muscleIntensities,
        highlightedMuscles: highlightedMuscles,
        interactive: false,
      ),
    );
  }
}
