import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../exercises/presentation/providers/exercise_provider.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../../../programs/presentation/providers/program_provider.dart';
import '../../../programs/data/models/program_model.dart';
import '../../../programs/data/models/program_week_model.dart';
import '../../../programs/presentation/screens/program_builder_screen.dart';
import '../providers/trainer_provider.dart';
import '../widgets/quick_stats_grid.dart';
import '../widgets/trainee_card.dart';
import '../widgets/notification_badge.dart';

class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(trainerStatsProvider);
    final traineesAsync = ref.watch(traineesProvider);
    final impersonation = ref.watch(impersonationProvider);
    final exercisesAsync = ref.watch(exercisesProvider(const ExerciseFilter()));
    final programsAsync = ref.watch(programTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Dashboard'),
        actions: [
          NotificationBadge(
            onTap: () => context.push('/trainer/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () => context.push('/trainer/ai-chat'),
            tooltip: 'AI Assistant',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/trainer/invite'),
            tooltip: 'Invite Trainee',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: impersonation.isImpersonating
          ? _buildImpersonationBanner(context, ref, impersonation)
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(trainerStatsProvider);
                ref.invalidate(traineesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    statsAsync.when(
                      data: (stats) => stats != null
                          ? QuickStatsGrid(stats: stats)
                          : const SizedBox(),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 24),

                    // Programs Carousel
                    _buildSectionHeader(
                      context,
                      'Your Programs',
                      onViewAll: () => context.push('/trainer/programs'),
                    ),
                    const SizedBox(height: 12),
                    programsAsync.when(
                      data: (programs) => _buildProgramsCarousel(context, programs),
                      loading: () => _buildCarouselShimmer(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 24),

                    // Exercises Carousel
                    _buildSectionHeader(
                      context,
                      'Exercise Library',
                      onViewAll: () => context.push('/trainer/exercises'),
                    ),
                    const SizedBox(height: 12),
                    exercisesAsync.when(
                      data: (exercises) => _buildExercisesCarousel(context, exercises),
                      loading: () => _buildCarouselShimmer(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 24),

                    // Recent Trainees
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Trainees',
                          style: theme.textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () => context.push('/trainer/trainees'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    traineesAsync.when(
                      data: (trainees) {
                        if (trainees.isEmpty) {
                          return _buildEmptyState(context);
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: trainees.length.clamp(0, 5),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return TraineeCard(
                              trainee: trainees[index],
                              onTap: () => context.push(
                                '/trainer/trainees/${trainees[index].id}',
                              ),
                              onLoginAs: () => _startImpersonation(
                                context,
                                ref,
                                trainees[index].id,
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trainer/invite'),
        icon: const Icon(Icons.person_add),
        label: const Text('Invite'),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onViewAll}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge,
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildCarouselShimmer() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramsCarousel(BuildContext context, List<ProgramTemplateModel> programs) {
    final theme = Theme.of(context);

    if (programs.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month, size: 32, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 8),
              Text(
                'No programs yet',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push('/trainer/programs'),
                child: const Text('Create Program'),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: programs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final program = programs[index];
          return _buildProgramCard(context, program);
        },
      ),
    );
  }

  Widget _buildProgramCard(BuildContext context, ProgramTemplateModel program) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showProgramDetail(context, program),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              program.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Text(
                  '${program.durationWeeks} weeks',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProgramDetail(BuildContext context, ProgramTemplateModel program) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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

              // Title
              Text(
                program.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (program.description != null && program.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  program.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _buildStatChip(context, Icons.schedule, '${program.durationWeeks} weeks'),
                  const SizedBox(width: 12),
                  _buildStatChip(context, Icons.fitness_center, program.difficultyDisplay),
                  const SizedBox(width: 12),
                  _buildStatChip(context, Icons.flag, program.goalTypeDisplay),
                ],
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Parse existing weeks from schedule_template
                        List<ProgramWeek>? existingWeeks;
                        if (program.scheduleTemplate != null) {
                          try {
                            final scheduleData = program.scheduleTemplate;
                            List<dynamic>? weeksData;
                            if (scheduleData is List) {
                              weeksData = scheduleData;
                            } else if (scheduleData is Map<String, dynamic>) {
                              weeksData = scheduleData['weeks'] as List<dynamic>?;
                            }
                            if (weeksData != null && weeksData.isNotEmpty) {
                              existingWeeks = weeksData
                                  .map((w) => ProgramWeek.fromJson(w as Map<String, dynamic>))
                                  .toList();
                            }
                          } catch (e) {
                            // Schedule template parsing failed — fall through to empty weeks
                          }
                        }
                        // Navigate to program builder to edit
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgramBuilderScreen(
                              templateName: program.name,
                              durationWeeks: program.durationWeeks,
                              difficulty: program.difficultyLevel,
                              goal: program.goalType,
                              existingTemplateId: program.id,
                              existingWeeks: existingWeeks,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAssignToTraineeDialog(context, program);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Assign'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAssignToTraineeDialog(BuildContext context, ProgramTemplateModel program) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Consumer(
          builder: (context, ref, child) {
            final traineesAsync = ref.watch(traineesProvider);

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                        'Select Trainee',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a trainee to assign "${program.name}"',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Trainee list
                Expanded(
                  child: traineesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Error: $error'),
                    ),
                    data: (trainees) {
                      if (trainees.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: theme.hintColor),
                              const SizedBox(height: 16),
                              Text(
                                'No Trainees Yet',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Invite trainees first',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: trainees.length,
                        itemBuilder: (context, index) {
                          final trainee = trainees[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Text(
                                  trainee.displayName.isNotEmpty
                                      ? trainee.displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                trainee.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(trainee.email),
                              trailing: Icon(Icons.chevron_right, color: theme.hintColor),
                              onTap: () {
                                Navigator.pop(context);
                                // Navigate to program builder with trainee ID
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProgramBuilderScreen(
                                      traineeId: trainee.id,
                                      templateName: program.name,
                                      durationWeeks: program.durationWeeks,
                                      difficulty: program.difficultyLevel,
                                      goal: program.goalType,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildExercisesCarousel(BuildContext context, List<ExerciseModel> exercises) {
    final theme = Theme.of(context);

    if (exercises.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 32, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 8),
              Text(
                'No exercises yet',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: exercises.length.clamp(0, 10),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return _buildExerciseCard(context, exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseModel exercise) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showExerciseDetail(context, exercise),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Muscle group image thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      exercise.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        child: Icon(Icons.fitness_center, color: theme.colorScheme.secondary),
                      ),
                    ),
                    // Gradient overlay for better text visibility
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        exercise.muscleGroupDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
              // Muscle group
              Row(
                children: [
                  Icon(Icons.category, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Muscle Group: ',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                  Text(
                    exercise.muscleGroupDisplay,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
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
                _buildYouTubeThumbnail(context, exercise.videoUrl!),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVideoUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open video')),
          );
        }
      }
    }
  }

  Widget _buildYouTubeThumbnail(BuildContext context, String videoUrl) {
    final theme = Theme.of(context);
    final videoId = _extractYouTubeVideoId(videoUrl);

    if (videoId == null) {
      // Not a valid YouTube URL, show generic button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openVideoUrl(context, videoUrl),
          icon: const Icon(Icons.play_circle_filled),
          label: const Text('Watch Tutorial Video'),
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
      onTap: () => _openVideoUrl(context, videoUrl),
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
                      color: theme.dividerColor,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.dividerColor,
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

  Widget _buildImpersonationBanner(
    BuildContext context,
    WidgetRef ref,
    ImpersonationState state,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          color: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Viewing as Trainee',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.trainee?.email ?? '',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (state.session?.isReadOnly ?? true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'READ ONLY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _endImpersonation(context, ref),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 64, color: theme.textTheme.bodySmall?.color),
                const SizedBox(height: 16),
                Text(
                  'Viewing ${state.trainee?.firstName ?? state.trainee?.email ?? "Trainee"}\'s Experience',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Navigate to see what your trainee sees',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/home'),
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Trainee Home'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.group_add,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No Trainees Yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Invite your first trainee to get started',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/trainer/invite'),
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Trainee'),
            ),
          ],
        ),
      ),
    );
  }

  void _startImpersonation(BuildContext context, WidgetRef ref, int traineeId) async {
    final result = await ref.read(impersonationProvider.notifier).startImpersonation(traineeId);

    if (!result['success']) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to start session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (context.mounted) {
      // Navigate directly to trainee home
      context.go('/home');
    }
  }

  void _endImpersonation(BuildContext context, WidgetRef ref) async {
    await ref.read(impersonationProvider.notifier).endImpersonation();
    ref.invalidate(trainerStatsProvider);
    ref.invalidate(traineesProvider);
  }
}
