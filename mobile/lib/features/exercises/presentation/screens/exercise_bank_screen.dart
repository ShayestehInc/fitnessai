import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/exercise_model.dart';
import '../providers/exercise_provider.dart';

class ExerciseBankScreen extends ConsumerStatefulWidget {
  const ExerciseBankScreen({super.key});

  @override
  ConsumerState<ExerciseBankScreen> createState() => _ExerciseBankScreenState();
}

class _ExerciseBankScreenState extends ConsumerState<ExerciseBankScreen> {
  final _searchController = TextEditingController();
  String? _selectedMuscleGroup;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ExerciseFilter(
      muscleGroup: _selectedMuscleGroup,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
    final exercisesAsync = ref.watch(exercisesProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExerciseDialog(context),
            tooltip: 'Add Custom Exercise',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Muscle group filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(context, 'All', null),
                const SizedBox(width: 8),
                ...MuscleGroups.all.map((group) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(context, MuscleGroups.displayName(group), group),
                )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(exercisesProvider(filter)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildExerciseList(context, exercises);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String? value) {
    final theme = Theme.of(context);
    final isSelected = _selectedMuscleGroup == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMuscleGroup = selected ? value : null;
        });
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: theme.textTheme.bodySmall?.color),
          const SizedBox(height: 16),
          Text(
            'No exercises found',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context, List<ExerciseModel> exercises) {
    // Group exercises by muscle group
    final grouped = <String, List<ExerciseModel>>{};
    for (final exercise in exercises) {
      grouped.putIfAbsent(exercise.muscleGroup, () => []).add(exercise);
    }

    if (_selectedMuscleGroup != null) {
      // Show flat list when filtered
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return _buildExerciseCard(context, exercises[index]);
        },
      );
    }

    // Show grouped list
    final sortedKeys = grouped.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final muscleGroup = sortedKeys[index];
        final groupExercises = grouped[muscleGroup]!;
        return _buildMuscleGroupSection(context, muscleGroup, groupExercises);
      },
    );
  }

  Widget _buildMuscleGroupSection(BuildContext context, String muscleGroup, List<ExerciseModel> exercises) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMuscleGroupIcon(muscleGroup),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                MuscleGroups.displayName(muscleGroup),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${exercises.length}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        ...exercises.map((e) => _buildExerciseCard(context, e)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseModel exercise) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showExerciseDetail(context, exercise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category, size: 14, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          exercise.muscleGroupDisplay,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup) {
      case 'chest': return Icons.accessibility_new;
      case 'back': return Icons.accessibility;
      case 'shoulders': return Icons.accessibility_new;
      case 'biceps': return Icons.fitness_center;
      case 'triceps': return Icons.fitness_center;
      case 'quadriceps': return Icons.directions_walk;
      case 'hamstrings': return Icons.directions_walk;
      case 'calves': return Icons.directions_walk;
      case 'glutes': return Icons.airline_seat_legroom_reduced;
      case 'core': return Icons.radio_button_checked;
      case 'cardio': return Icons.favorite;
      case 'full_body': return Icons.person;
      default: return Icons.fitness_center;
    }
  }

  void _showExerciseDetail(BuildContext context, ExerciseModel exercise) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                exercise.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(context, Icons.category, 'Muscle Group', exercise.muscleGroupDisplay),
              if (exercise.description != null && exercise.description!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(exercise.description!),
              ],
              if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openYouTubeVideo(exercise.videoUrl!),
                    icon: const Icon(Icons.play_circle_filled),
                    label: const Text('Watch Tutorial Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final videoUrlController = TextEditingController();
    final customMuscleGroupController = TextEditingController();
    String selectedMuscleGroup = MuscleGroups.chest;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Add Custom Exercise',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Exercise name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name *',
                    hintText: 'e.g., Incline Dumbbell Press',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Muscle group dropdown
                DropdownButtonFormField<String>(
                  value: selectedMuscleGroup,
                  decoration: const InputDecoration(
                    labelText: 'Muscle Group *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: MuscleGroups.all.map((group) {
                    return DropdownMenuItem(
                      value: group,
                      child: Text(MuscleGroups.displayName(group)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedMuscleGroup = value);
                    }
                  },
                ),

                // Custom muscle group text field (shown when "Other" is selected)
                if (selectedMuscleGroup == MuscleGroups.other) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: customMuscleGroupController,
                    decoration: InputDecoration(
                      labelText: 'Custom Muscle Group (optional)',
                      hintText: 'e.g., Forearms, Neck, Hip Flexors...',
                      prefixIcon: const Icon(Icons.edit),
                      helperText: 'Leave empty to use "Other"',
                      helperStyle: TextStyle(color: theme.hintColor),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'How to perform this exercise...',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Video URL
                TextField(
                  controller: videoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Video URL (optional)',
                    hintText: 'https://youtube.com/...',
                    prefixIcon: Icon(Icons.play_circle_outline),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter an exercise name'),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isLoading = true);

                            // Use custom muscle group if "Other" is selected and custom value provided
                            final muscleGroup = selectedMuscleGroup == MuscleGroups.other &&
                                    customMuscleGroupController.text.trim().isNotEmpty
                                ? customMuscleGroupController.text.trim().toLowerCase().replaceAll(' ', '_')
                                : selectedMuscleGroup;

                            final repository = ref.read(exerciseRepositoryProvider);
                            final data = {
                              'name': name,
                              'muscle_group': muscleGroup,
                              if (descriptionController.text.trim().isNotEmpty)
                                'description': descriptionController.text.trim(),
                              if (videoUrlController.text.trim().isNotEmpty)
                                'video_url': videoUrlController.text.trim(),
                            };

                            final result = await repository.createCustomExercise(data);

                            if (!context.mounted) return;

                            if (result['success'] == true) {
                              Navigator.pop(context);
                              // Refresh the exercise list
                              ref.invalidate(exercisesProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Exercise "$name" created'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setDialogState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['error'] ?? 'Failed to create exercise'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Exercise'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openYouTubeVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video')),
        );
      }
    }
  }
}
