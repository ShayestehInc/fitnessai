import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/anatomy_provider.dart';

class ExercisesTab extends ConsumerWidget {
  final String slug;

  const ExercisesTab({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(muscleExercisesProvider(slug));
    final theme = Theme.of(context);

    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
      data: (exercises) {
        if (exercises.isEmpty) {
          return Center(
            child: Text(
              'No exercises found for this muscle.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(exercise.name),
                subtitle: Text(
                  exercise.muscleGroupDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
