import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/anatomy_provider.dart';
import '../widgets/body_map_widget.dart';
import '../widgets/intensity_legend.dart';
import '../widgets/layer_controls.dart';
import '../widgets/muscle_info_bottom_sheet.dart';
import '../widgets/zoom_controls.dart';

class AnatomyExplorerScreen extends ConsumerStatefulWidget {
  const AnatomyExplorerScreen({super.key});

  @override
  ConsumerState<AnatomyExplorerScreen> createState() =>
      _AnatomyExplorerScreenState();
}

class _AnatomyExplorerScreenState
    extends ConsumerState<AnatomyExplorerScreen> {
  bool _showCoverage = false;
  String _currentLayer = 'muscles';
  final _mapController = BodyMapController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverageAsync =
        _showCoverage ? ref.watch(muscleCoverageProvider('week')) : null;

    Map<String, double> intensities = {};
    int musclesTrained = 0;
    int musclesTotal = 21;

    if (_showCoverage && coverageAsync != null) {
      coverageAsync.whenData((coverage) {
        intensities = coverage.muscleIntensities;
        musclesTrained = coverage.musclesTrained;
        musclesTotal = coverage.musclesTotal;
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'ANATOMY',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        centerTitle: true,
        actions: [
          _CoverageToggle(
            showCoverage: _showCoverage,
            onToggle: () => setState(() => _showCoverage = !_showCoverage),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // 3D Body Map — full bleed
          Positioned.fill(
            child: BodyMapWidget(
              view: BodyMapView.front,
              muscleIntensities: intensities,
              onMuscleTapped: _onMuscleTapped,
              controller: _mapController,
            ),
          ),

          // Coverage summary card
          if (_showCoverage)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 16,
              right: 16,
              child: _CoverageSummaryCard(
                musclesTrained: musclesTrained,
                musclesTotal: musclesTotal,
              ),
            ),

          // Layer controls (left side)
          Positioned(
            left: 12,
            bottom: MediaQuery.of(context).padding.bottom + 80,
            child: LayerControls(
              currentLayer: _currentLayer,
              onLayerChanged: (layer) {
                setState(() => _currentLayer = layer);
                _mapController.setLayer(layer);
              },
            ),
          ),

          // Zoom controls (right side)
          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 80,
            child: ZoomControls(
              onZoomIn: _mapController.zoomIn,
              onZoomOut: _mapController.zoomOut,
              onReset: _mapController.resetCamera,
            ),
          ),

          // Intensity legend at bottom
          if (_showCoverage)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: const IntensityLegend(),
            ),
        ],
      ),
    );
  }

  void _onMuscleTapped(String muscleSlug) {
    final refsAsync = ref.read(muscleReferencesProvider);
    refsAsync.whenData((refs) {
      final match = refs.where((r) => r.slug == muscleSlug).firstOrNull;
      if (match != null && mounted) {
        MuscleInfoBottomSheet.show(
          context,
          muscleSlug: muscleSlug,
          displayName: match.displayName,
          latinName: match.latinName,
          description: match.description,
          bodyRegion: match.bodyRegion,
          movementCount: match.primaryMovements.length,
          exerciseCount: match.commonExercises.length,
        );
      }
    });
  }
}

class _CoverageToggle extends StatelessWidget {
  final bool showCoverage;
  final VoidCallback onToggle;

  const _CoverageToggle({
    required this.showCoverage,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: showCoverage
              ? const Color(0xFF6366F1).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: showCoverage
                ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showCoverage ? Icons.explore : Icons.whatshot,
              size: 14,
              color: showCoverage
                  ? const Color(0xFF6366F1)
                  : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              showCoverage ? 'Explore' : 'Coverage',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: showCoverage
                    ? const Color(0xFF6366F1)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverageSummaryCard extends StatelessWidget {
  final int musclesTrained;
  final int musclesTotal;

  const _CoverageSummaryCard({
    required this.musclesTrained,
    required this.musclesTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$musclesTrained/$musclesTotal muscles trained',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'THIS WEEK',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
