import 'package:flutter/material.dart';
import '../../data/models/parsed_log_model.dart';

/// Draft Log Card - Shows parsed data before confirmation
/// Displays nutrition and workout data in a clean card format
class DraftLogCard extends StatelessWidget {
  final ParsedLogModel parsedData;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isSaving;

  const DraftLogCard({
    super.key,
    required this.parsedData,
    required this.onConfirm,
    required this.onCancel,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasNutrition = parsedData.nutrition.meals.isNotEmpty;
    final hasWorkout = parsedData.workout.exercises.isNotEmpty;

    if (!hasNutrition && !hasWorkout) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Your Log',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (hasNutrition) ...[
              Text(
                'Nutrition',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...parsedData.nutrition.meals.map((meal) => _MealItem(meal: meal)),
              const SizedBox(height: 16),
            ],
            if (hasWorkout) ...[
              Text(
                'Workout',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...parsedData.workout.exercises.map((exercise) => _ExerciseItem(exercise: exercise)),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isSaving ? null : onConfirm,
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  final MealData meal;

  const _MealItem({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.restaurant, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              meal.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '${meal.calories.toInt()} kcal',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ExerciseItem extends StatelessWidget {
  final ExerciseData exercise;

  const _ExerciseItem({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final repsStr = exercise.reps is String
        ? exercise.reps as String
        : '${exercise.reps}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              exercise.exerciseName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '${exercise.sets} sets × $repsStr @ ${exercise.weight}${exercise.unit}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
