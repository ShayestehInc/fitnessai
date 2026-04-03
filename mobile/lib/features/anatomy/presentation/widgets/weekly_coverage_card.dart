import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/anatomy_provider.dart';
import 'body_map_widget.dart';

class WeeklyCoverageCard extends ConsumerWidget {
  const WeeklyCoverageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverageAsync = ref.watch(muscleCoverageProvider('week'));
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/anatomy'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Muscle Coverage',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              coverageAsync.when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      'Start training to see your muscle map!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                data: (coverage) => Column(
                  children: [
                    SizedBox(
                      height: 140,
                      child: BodyMapWidget(
                        view: BodyMapView.front,
                        muscleIntensities: coverage.muscleIntensities,
                        interactive: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${coverage.musclesTrained}/${coverage.musclesTotal} muscles trained this week',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
