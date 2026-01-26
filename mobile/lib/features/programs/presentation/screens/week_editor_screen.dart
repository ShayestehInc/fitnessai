import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/program_week_model.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../../../exercises/presentation/providers/exercise_provider.dart';

class WeekEditorScreen extends ConsumerStatefulWidget {
  final ProgramWeek week;
  final Function(ProgramWeek) onSave;

  const WeekEditorScreen({
    super.key,
    required this.week,
    required this.onSave,
  });

  @override
  ConsumerState<WeekEditorScreen> createState() => _WeekEditorScreenState();
}

class _WeekEditorScreenState extends ConsumerState<WeekEditorScreen> {
  late ProgramWeek _week;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _week = widget.week;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Week ${_week.weekNumber}'),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave(_week);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Day selector
          _buildDaySelector(),

          // Day content
          Expanded(
            child: _buildDayContent(_week.days[_selectedDayIndex]),
          ),
        ],
      ),
      floatingActionButton: _week.days[_selectedDayIndex].isRestDay
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddExerciseSheet(),
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
    );
  }

  Widget _buildDaySelector() {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = _week.days[index];
          final isSelected = index == _selectedDayIndex;

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : day.isRestDay
                        ? Colors.grey.withOpacity(0.1)
                        : AppTheme.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    day.isRestDay ? Icons.bed : Icons.fitness_center,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : day.isRestDay
                            ? Colors.grey
                            : AppTheme.primary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayContent(WorkoutDay day) {
    if (day.isRestDay) {
      return _buildRestDayContent(day);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: day.exercises.length + 1, // +1 for header
      onReorder: (oldIndex, newIndex) {
        if (oldIndex == 0 || newIndex == 0) return; // Don't reorder header
        final actualOld = oldIndex - 1;
        var actualNew = newIndex - 1;
        if (actualNew > actualOld) actualNew--;
        _reorderExercise(actualOld, actualNew);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            key: const ValueKey('header'),
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildDayHeader(day),
          );
        }

        final exercise = day.exercises[index - 1];
        return _buildExerciseCard(exercise, index - 1);
      },
    );
  }

  Widget _buildRestDayContent(WorkoutDay day) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.self_improvement, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Rest Day',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Recovery is essential for growth',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _convertToWorkoutDay(),
            icon: const Icon(Icons.fitness_center),
            label: const Text('Convert to Workout Day'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(WorkoutDay day) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.exercises.length} exercises • ${day.exercises.fold(0, (sum, e) => sum + e.sets)} sets',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Rename Day'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rest',
                child: Row(
                  children: [
                    Icon(Icons.bed, size: 18),
                    SizedBox(width: 8),
                    Text('Convert to Rest Day'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Exercises', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _showRenameDayDialog();
                  break;
                case 'rest':
                  _convertToRestDay();
                  break;
                case 'clear':
                  _clearExercises();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise, int index) {
    return Card(
      key: ValueKey(exercise.exerciseId.toString() + index.toString()),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Drag handle
            Icon(Icons.drag_handle, color: Colors.grey[400]),
            const SizedBox(width: 12),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exerciseName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMiniChip(exercise.muscleGroup),
                      const SizedBox(width: 8),
                      Text(
                        '${exercise.sets} × ${exercise.reps}',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showEditExerciseDialog(exercise, index),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => _removeExercise(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.replaceAll('_', ' ').split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
        style: TextStyle(color: Colors.grey[600], fontSize: 11),
      ),
    );
  }

  void _showAddExerciseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _ExercisePickerSheet(
          scrollController: scrollController,
          onExerciseSelected: (exercise) {
            _addExercise(exercise);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _addExercise(ExerciseModel exercise) {
    setState(() {
      final day = _week.days[_selectedDayIndex];
      final newExercise = WorkoutExercise(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        muscleGroup: exercise.muscleGroup,
        sets: 3,
        reps: 10,
      );

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(
        exercises: [...day.exercises, newExercise],
      );

      _week = _week.copyWith(days: updatedDays);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      final day = _week.days[_selectedDayIndex];
      final updatedExercises = List<WorkoutExercise>.from(day.exercises);
      updatedExercises.removeAt(index);

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(exercises: updatedExercises);

      _week = _week.copyWith(days: updatedDays);
    });
  }

  void _reorderExercise(int oldIndex, int newIndex) {
    setState(() {
      final day = _week.days[_selectedDayIndex];
      final updatedExercises = List<WorkoutExercise>.from(day.exercises);
      final item = updatedExercises.removeAt(oldIndex);
      updatedExercises.insert(newIndex, item);

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(exercises: updatedExercises);

      _week = _week.copyWith(days: updatedDays);
    });
  }

  void _showEditExerciseDialog(WorkoutExercise exercise, int index) {
    int sets = exercise.sets;
    int reps = exercise.reps;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                exercise.exerciseName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Sets
              Row(
                children: [
                  const SizedBox(width: 60, child: Text('Sets:')),
                  IconButton(
                    onPressed: () {
                      if (sets > 1) setModalState(() => sets--);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    sets.toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      if (sets < 10) setModalState(() => sets++);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),

              // Reps
              Row(
                children: [
                  const SizedBox(width: 60, child: Text('Reps:')),
                  IconButton(
                    onPressed: () {
                      if (reps > 1) setModalState(() => reps--);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    reps.toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      if (reps < 50) setModalState(() => reps++);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick presets
              const Text('Quick Presets:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetChip('3×8', () => setModalState(() { sets = 3; reps = 8; })),
                  _buildPresetChip('3×10', () => setModalState(() { sets = 3; reps = 10; })),
                  _buildPresetChip('3×12', () => setModalState(() { sets = 3; reps = 12; })),
                  _buildPresetChip('4×8', () => setModalState(() { sets = 4; reps = 8; })),
                  _buildPresetChip('4×10', () => setModalState(() { sets = 4; reps = 10; })),
                  _buildPresetChip('5×5', () => setModalState(() { sets = 5; reps = 5; })),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _updateExercise(index, sets, reps);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }

  void _updateExercise(int index, int sets, int reps) {
    setState(() {
      final day = _week.days[_selectedDayIndex];
      final updatedExercises = List<WorkoutExercise>.from(day.exercises);
      updatedExercises[index] = updatedExercises[index].copyWith(sets: sets, reps: reps);

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(exercises: updatedExercises);

      _week = _week.copyWith(days: updatedDays);
    });
  }

  void _showRenameDayDialog() {
    final controller = TextEditingController(text: _week.days[_selectedDayIndex].name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Day'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Day Name',
            hintText: 'e.g., Push, Pull, Upper',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final updatedDays = List<WorkoutDay>.from(_week.days);
                updatedDays[_selectedDayIndex] = updatedDays[_selectedDayIndex].copyWith(
                  name: controller.text,
                );
                _week = _week.copyWith(days: updatedDays);
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _convertToRestDay() {
    setState(() {
      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = WorkoutDay(
        name: 'Rest',
        isRestDay: true,
        exercises: [],
      );
      _week = _week.copyWith(days: updatedDays);
    });
  }

  void _convertToWorkoutDay() {
    setState(() {
      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = WorkoutDay(
        name: 'Workout',
        isRestDay: false,
        exercises: [],
      );
      _week = _week.copyWith(days: updatedDays);
    });
  }

  void _clearExercises() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Exercises'),
        content: const Text('Are you sure you want to remove all exercises from this day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                final updatedDays = List<WorkoutDay>.from(_week.days);
                updatedDays[_selectedDayIndex] = updatedDays[_selectedDayIndex].copyWith(
                  exercises: [],
                );
                _week = _week.copyWith(days: updatedDays);
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Function(ExerciseModel) onExerciseSelected;

  const _ExercisePickerSheet({
    required this.scrollController,
    required this.onExerciseSelected,
  });

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final _searchController = TextEditingController();
  String? _selectedMuscleGroup;

  @override
  Widget build(BuildContext context) {
    final filter = ExerciseFilter(
      muscleGroup: _selectedMuscleGroup,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
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
            color: Colors.grey[300],
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
              fillColor: AppTheme.muted,
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
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
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
