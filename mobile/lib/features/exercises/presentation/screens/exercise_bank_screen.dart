import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_dropdown.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_search_bar.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/exercise_model.dart';
import '../providers/exercise_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

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
        title: Text(context.l10n.exercisesExerciseLibrary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExerciseDialog(context),
            tooltip: context.l10n.exercisesAddCustomExercise,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AdaptiveSearchBar(
              controller: _searchController,
              placeholder: 'Search exercises...',
              onChanged: (value) => setState(() {}),
              onClear: () => setState(() {}),
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
              loading: () => const Center(child: AdaptiveSpinner()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(context.l10n.exercisesErrorerror),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(exercisesProvider(filter)),
                      child: Text(context.l10n.commonRetry),
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
      child: AdaptiveTappable(
        onTap: () => _showExerciseDetail(context, exercise),
        onLongPress: () {
          HapticService.mediumTap();
          _showExerciseQuickActions(context, exercise);
        },
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(12),
        child: Row(
            children: [
              // Exercise thumbnail image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 48,
                  child: Image.network(
                    exercise.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.fitness_center, color: theme.colorScheme.primary),
                    ),
                  ),
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
    // Capture the parent context before showing the bottom sheet
    final parentContext = context;

    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
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
              _buildDetailRow(parentContext, Icons.category, 'Muscle Group', exercise.muscleGroupDisplay),
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
                Text(
                  'Tutorial Video',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // YouTube thumbnail
                _buildYouTubeThumbnail(parentContext, exercise.videoUrl!),
              ],
              const SizedBox(height: 24),
              // Edit buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        // Use parent context for the new dialog
                        if (parentContext.mounted) {
                          _showEditImageDialog(parentContext, exercise);
                        }
                      },
                      icon: const Icon(Icons.image, size: 18),
                      label: Text(context.l10n.exercisesEditImage),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        // Use parent context for the new dialog
                        if (parentContext.mounted) {
                          _showEditVideoDialog(parentContext, exercise);
                        }
                      },
                      icon: const Icon(Icons.videocam, size: 18),
                      label: Text(context.l10n.exercisesEditVideo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // v6.5 quick-access buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        if (parentContext.mounted) {
                          parentContext.push('/lift-history/${exercise.id}?name=${Uri.encodeComponent(exercise.name)}');
                        }
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Lift History'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        if (parentContext.mounted) {
                          parentContext.push('/auto-tag/${exercise.id}?name=${Uri.encodeComponent(exercise.name)}');
                        }
                      },
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: const Text('Auto-Tag'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeThumbnail(BuildContext context, String videoUrl) {
    final videoId = _extractYouTubeVideoId(videoUrl);
    if (videoId == null) {
      // Not a valid YouTube URL, show generic button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openYouTubeVideo(videoUrl),
          icon: const Icon(Icons.play_circle_filled),
          label: Text(context.l10n.exercisesWatchTutorialVideo),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return GestureDetector(
      onTap: () => _openYouTubeVideo(videoUrl),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: AdaptiveSpinner(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.video_library, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              // Play button overlay
              Container(
                width: 68,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              // Tap to play text
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Open in YouTube',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              // YouTube branding
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_filled, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'YouTube',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _extractYouTubeVideoId(String url) {
    // Handle various YouTube URL formats
    // https://www.youtube.com/watch?v=VIDEO_ID
    // https://youtu.be/VIDEO_ID
    // https://www.youtube.com/embed/VIDEO_ID
    // https://www.youtube.com/v/VIDEO_ID

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtube.com/watch?v=
    if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }

    // youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    // youtube.com/embed/VIDEO_ID or youtube.com/v/VIDEO_ID
    if (uri.host.contains('youtube.com') && uri.pathSegments.length >= 2) {
      final firstSegment = uri.pathSegments.first;
      if (firstSegment == 'embed' || firstSegment == 'v') {
        return uri.pathSegments[1];
      }
    }

    return null;
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

    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  decoration: InputDecoration(
                    labelText: context.l10n.exercisesExerciseName,
                    hintText: context.l10n.exercisesEGInclineDumbbellPress,
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Muscle group dropdown
                AdaptiveDropdown<String>(
                  value: selectedMuscleGroup,
                  decoration: InputDecoration(
                    labelText: context.l10n.exercisesMuscleGroup,
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: MuscleGroups.all.map((group) {
                    return AdaptiveDropdownItem(
                      value: group,
                      label: MuscleGroups.displayName(group),
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
                      labelText: context.l10n.exercisesCustomMuscleGroupOptional,
                      hintText: context.l10n.exercisesEGForearmsNeckHipFlexors,
                      prefixIcon: const Icon(Icons.edit),
                      helperText: context.l10n.exercisesLeaveEmptyToUseOther,
                      helperStyle: TextStyle(color: theme.hintColor),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: context.l10n.adminDescriptionOptional,
                    hintText: context.l10n.exercisesHowToPerformThisExercise,
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
                  decoration: InputDecoration(
                    labelText: context.l10n.exercisesVideoURLOptional,
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
                              showAdaptiveToast(context, message: context.l10n.exercisesPleaseEnterAnExerciseName);
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
                              showAdaptiveToast(context, message: context.l10n.exercisesExercisenameCreated, type: ToastType.success);
                            } else {
                              setDialogState(() => isLoading = false);
                              showAdaptiveToast(context, message: result['error'] ?? 'Failed to create exercise', type: ToastType.error);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const AdaptiveSpinner.small()
                        : Text(context.l10n.exercisesCreateExercise),
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
        showAdaptiveToast(context, message: context.l10n.exercisesCouldNotOpenVideo, type: ToastType.error);
      }
    }
  }

  void _showExerciseQuickActions(BuildContext context, ExerciseModel exercise) {
    final theme = Theme.of(context);
    // Capture the parent context before showing the bottom sheet
    final parentContext = context;

    showAdaptiveBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                exercise.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text(context.l10n.exercisesEditImage),
                subtitle: Text(context.l10n.exercisesChangeTheExerciseThumbnail),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (parentContext.mounted) {
                    _showEditImageDialog(parentContext, exercise);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(context.l10n.exercisesViewDetails),
                subtitle: Text(context.l10n.exercisesSeeFullExerciseInformation),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (parentContext.mounted) {
                    _showExerciseDetail(parentContext, exercise);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Lift History'),
                subtitle: const Text('View your set logs for this exercise'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (parentContext.mounted) {
                    parentContext.push('/lift-history/${exercise.id}?name=${Uri.encodeComponent(exercise.name)}');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: const Text('Auto-Tag'),
                subtitle: const Text('Run AI tagging on this exercise'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (parentContext.mounted) {
                    parentContext.push('/auto-tag/${exercise.id}?name=${Uri.encodeComponent(exercise.name)}');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('Tag History'),
                subtitle: const Text('View tagging history and changes'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (parentContext.mounted) {
                    parentContext.push(
                      '/tag-history/${exercise.id}?name=${Uri.encodeComponent(exercise.name)}',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditImageDialog(BuildContext context, ExerciseModel exercise) {
    final theme = Theme.of(context);
    bool isUploading = false;
    File? selectedImageFile;

    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  'Edit Exercise Image',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 24),

                // Current/Preview image
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 200,
                      height: 150,
                      child: selectedImageFile != null
                          ? Image.file(
                              selectedImageFile!,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              exercise.thumbnailUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Center(child: AdaptiveSpinner()),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: theme.colorScheme.errorContainer,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: theme.colorScheme.error, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No image',
                                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upload from Gallery button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isUploading
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1080,
                              imageQuality: 85,
                            );

                            if (pickedFile != null) {
                              setDialogState(() {
                                selectedImageFile = File(pickedFile.path);
                              });
                            }
                          },
                    icon: const Icon(Icons.photo_library),
                    label: Text(selectedImageFile != null ? 'Change Image' : 'Upload from Gallery'),
                  ),
                ),

                if (selectedImageFile != null) ...[
                  const SizedBox(height: 12),
                  // Upload button when image is selected
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              setDialogState(() => isUploading = true);

                              final repository = ref.read(exerciseRepositoryProvider);
                              final result = await repository.uploadExerciseImage(
                                exercise.id,
                                selectedImageFile!,
                              );

                              if (!context.mounted) return;

                              if (result['success'] == true) {
                                Navigator.pop(context);
                                ref.invalidate(exercisesProvider);
                                showAdaptiveToast(context, message: context.l10n.exercisesImageUploadedSuccessfully, type: ToastType.success);
                              } else {
                                setDialogState(() => isUploading = false);
                                showAdaptiveToast(context, message: result['error'] ?? 'Failed to upload image', type: ToastType.error);
                              }
                            },
                      icon: isUploading
                          ? const AdaptiveSpinner.small()
                          : const Icon(Icons.cloud_upload),
                      label: Text(isUploading ? 'Uploading...' : 'Upload Image'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedImageFile = null;
                        });
                      },
                      child: Text(context.l10n.exercisesClearSelection),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.commonCancel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditVideoDialog(BuildContext context, ExerciseModel exercise) {
    final theme = Theme.of(context);
    final videoUrlController = TextEditingController(text: exercise.videoUrl ?? '');
    bool isLoading = false;
    bool isUploading = false;
    String? previewVideoId;
    File? selectedVideoFile;

    // Extract initial video ID for preview
    if (exercise.videoUrl != null) {
      previewVideoId = _extractYouTubeVideoId(exercise.videoUrl!);
    }

    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  'Edit Exercise Video',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 24),

                // Current/Preview video thumbnail
                if (previewVideoId != null || selectedVideoFile != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 280,
                        height: 158,
                        child: selectedVideoFile != null
                            ? Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam, size: 48, color: theme.colorScheme.primary),
                                    const SizedBox(height: 8),
                                    Text(
                                      selectedVideoFile!.path.split('/').last,
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    'https://img.youtube.com/vi/$previewVideoId/hqdefault.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.video_library, size: 48),
                                    ),
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    child: const Center(
                                      child: Icon(Icons.play_circle_filled, size: 48, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Upload from Gallery button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading || isUploading
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickVideo(
                              source: ImageSource.gallery,
                              maxDuration: const Duration(minutes: 5),
                            );

                            if (pickedFile != null) {
                              setDialogState(() {
                                selectedVideoFile = File(pickedFile.path);
                                previewVideoId = null;
                                videoUrlController.clear();
                              });
                            }
                          },
                    icon: const Icon(Icons.video_library),
                    label: Text(selectedVideoFile != null ? 'Change Video' : 'Upload from Gallery'),
                  ),
                ),

                if (selectedVideoFile != null) ...[
                  const SizedBox(height: 12),
                  // Upload button when video is selected
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              setDialogState(() => isUploading = true);

                              final repository = ref.read(exerciseRepositoryProvider);
                              final result = await repository.uploadExerciseVideo(
                                exercise.id,
                                selectedVideoFile!,
                              );

                              if (!context.mounted) return;

                              if (result['success'] == true) {
                                Navigator.pop(context);
                                ref.invalidate(exercisesProvider);
                                showAdaptiveToast(context, message: context.l10n.exercisesVideoUploadedSuccessfully, type: ToastType.success);
                              } else {
                                setDialogState(() => isUploading = false);
                                showAdaptiveToast(context, message: result['error'] ?? 'Failed to upload video', type: ToastType.error);
                              }
                            },
                      icon: isUploading
                          ? const AdaptiveSpinner.small()
                          : const Icon(Icons.cloud_upload),
                      label: Text(isUploading ? 'Uploading...' : 'Upload Video'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedVideoFile = null;
                        });
                      },
                      child: Text(context.l10n.exercisesClearSelection),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Divider with "OR" text
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),
                const SizedBox(height: 16),

                // YouTube URL input
                TextField(
                  controller: videoUrlController,
                  enabled: selectedVideoFile == null,
                  decoration: InputDecoration(
                    labelText: context.l10n.exercisesYoutubeURL,
                    hintText: 'https://www.youtube.com/watch?v=...',
                    prefixIcon: const Icon(Icons.link),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.preview),
                      tooltip: context.l10n.exercisesPreview,
                      onPressed: selectedVideoFile == null
                          ? () {
                              final url = videoUrlController.text.trim();
                              final videoId = _extractYouTubeVideoId(url);
                              if (videoId != null) {
                                setDialogState(() => previewVideoId = videoId);
                              } else if (url.isNotEmpty) {
                                showAdaptiveToast(context, message: context.l10n.exercisesInvalidYouTubeURL, type: ToastType.error);
                              }
                            }
                          : null,
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  onSubmitted: (value) {
                    if (selectedVideoFile == null) {
                      final videoId = _extractYouTubeVideoId(value.trim());
                      if (videoId != null) {
                        setDialogState(() => previewVideoId = videoId);
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste a YouTube video URL for the exercise tutorial',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.l10n.commonCancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: (isLoading || isUploading || selectedVideoFile != null)
                            ? null
                            : () async {
                                final newUrl = videoUrlController.text.trim();

                                setDialogState(() => isLoading = true);

                                final repository = ref.read(exerciseRepositoryProvider);
                                final result = await repository.updateExercise(
                                  exercise.id,
                                  {'video_url': newUrl.isEmpty ? null : newUrl},
                                );

                                if (!context.mounted) return;

                                if (result['success'] == true) {
                                  Navigator.pop(context);
                                  ref.invalidate(exercisesProvider);
                                  showAdaptiveToast(context, message: context.l10n.exercisesVideoURLUpdated, type: ToastType.success);
                                } else {
                                  setDialogState(() => isLoading = false);
                                  showAdaptiveToast(context, message: result['error'] ?? 'Failed to update video', type: ToastType.error);
                                }
                              },
                        child: isLoading
                            ? const AdaptiveSpinner.small()
                            : Text(context.l10n.exercisesSaveURL),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

