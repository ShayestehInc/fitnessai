import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/anatomy_provider.dart';
import '../widgets/body_map_widget.dart';
import 'muscle_detail_tabs/about_tab.dart';
import 'muscle_detail_tabs/exercises_tab.dart';
import 'muscle_detail_tabs/movements_tab.dart';

class MuscleDetailScreen extends ConsumerWidget {
  final String slug;

  const MuscleDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleAsync = ref.watch(muscleDetailProvider(slug));
    final theme = Theme.of(context);
    const accent = Color(0xFF6366F1);

    final view = MuscleViewMapping.frontMuscles.contains(slug)
        ? BodyMapView.front
        : BodyMapView.back;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: muscleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
        data: (muscle) => DefaultTabController(
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF09090B),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // 3D body map hero
                      Positioned.fill(
                        child: BodyMapWidget(
                          view: view,
                          highlightedMuscles: {
                            slug: accent,
                          },
                          interactive: false,
                        ),
                      ),
                      // Gradient overlay at bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 120,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xFF09090B),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Muscle info overlay
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                muscle.bodyRegion
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: accent.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              muscle.displayName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (muscle.latinName.isNotEmpty)
                              Text(
                                muscle.latinName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Movements'),
                      Tab(text: 'Exercises'),
                    ],
                    labelColor: accent,
                    unselectedLabelColor:
                        Colors.white.withValues(alpha: 0.45),
                    indicatorColor: accent,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                AboutTab(muscle: muscle),
                MovementsTab(muscle: muscle),
                ExercisesTab(slug: slug),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF09090B),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
