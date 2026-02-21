import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../../../exercises/presentation/providers/exercise_provider.dart';

class ExercisePickerSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Function(ExerciseModel) onExerciseSelected;

  const ExercisePickerSheet({
    super.key,
    required this.scrollController,
    required this.onExerciseSelected,
  });

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  String? _selectedMuscleGroup;
  String? _selectedDifficulty;

  static const _difficultyOptions = ['beginner', 'intermediate', 'advanced'];
  static const _difficultyLabels = {
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ExerciseFilter(
      muscleGroup: _selectedMuscleGroup,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      difficultyLevel: _selectedDifficulty,
    );
    final exercisesAsync = ref.watch(exercisesProvider(filter));

    return Column(
      children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Add Exercise',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 16),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),

        const SizedBox(height: 12),

        // Muscle group filter
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedMuscleGroup == null,
                onSelected: (selected) {
                  setState(() => _selectedMuscleGroup = null);
                },
              ),
              const SizedBox(width: 8),
              ...MuscleGroups.all.map((group) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(MuscleGroups.displayName(group)),
                  selected: _selectedMuscleGroup == group,
                  onSelected: (selected) {
                    setState(() => _selectedMuscleGroup = selected ? group : null);
                  },
                ),
              )),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Difficulty filter
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _difficultyOptions.map((level) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  _difficultyLabels[level] ?? level,
                  style: const TextStyle(fontSize: 12),
                ),
                selected: _selectedDifficulty == level,
                onSelected: (selected) {
                  setState(() => _selectedDifficulty = selected ? level : null);
                },
                visualDensity: VisualDensity.compact,
              ),
            )).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Exercise list
        Expanded(
          child: exercisesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (exercises) {
              if (exercises.isEmpty) {
                return const Center(child: Text('No exercises found'));
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.fitness_center, color: theme.colorScheme.primary, size: 20),
                    ),
                    title: Text(exercise.name),
                    subtitle: Text(exercise.muscleGroupDisplay),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => widget.onExerciseSelected(exercise),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
