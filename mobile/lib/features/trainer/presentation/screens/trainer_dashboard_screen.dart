import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../exercises/presentation/providers/exercise_provider.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../../../programs/presentation/providers/program_provider.dart';
import '../../../programs/data/models/program_model.dart';
import '../providers/trainer_provider.dart';
import '../widgets/quick_stats_grid.dart';
import '../widgets/trainee_card.dart';

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
      onTap: () => context.push('/trainer/programs/${program.id}'),
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
      onTap: () => context.push('/trainer/exercises'),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
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
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fitness_center,
                color: theme.colorScheme.secondary,
                size: 18,
              ),
            ),
            const SizedBox(height: 10),
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
    );
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
