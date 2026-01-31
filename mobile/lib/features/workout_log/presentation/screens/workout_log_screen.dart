import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';
import '../../data/models/workout_models.dart';

class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutStateProvider.notifier).loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(workoutStateProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: state.isLoading && state.dailySummary == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(workoutStateProvider.notifier).loadInitialData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(state),
                        const SizedBox(height: 24),

                        // Date navigator
                        _buildDateNavigator(state),
                        const SizedBox(height: 24),

                        // Program card
                        if (state.activeProgram != null)
                          _buildProgramCard(state.activeProgram!),
                        const SizedBox(height: 24),

                        // Exercises section
                        _buildExercisesSection(state),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai-command'),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.mic),
        label: const Text('Log Workout'),
      ),
    );
  }

  Widget _buildHeader(WorkoutState state) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Logbook',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        IconButton(
          onPressed: () => context.push('/workout-calendar'),
          icon: const Icon(Icons.calendar_month),
          color: theme.textTheme.bodySmall?.color,
        ),
      ],
    );
  }

  Widget _buildDateNavigator(WorkoutState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                ref.read(workoutStateProvider.notifier).goToPreviousDay(),
            icon: const Icon(Icons.chevron_left),
            color: theme.textTheme.bodySmall?.color,
          ),
          GestureDetector(
            onTap: () => ref.read(workoutStateProvider.notifier).goToToday(),
            child: Text(
              state.formattedDate,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(workoutStateProvider.notifier).goToNextDay(),
            icon: const Icon(Icons.chevron_right),
            color: theme.textTheme.bodySmall?.color,
          ),
        ],
      ),
    );
  }

  String _formatStartDateLabel(String? startDate) {
    if (startDate == null) return 'N/A';
    try {
      final date = DateTime.parse(startDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDay = DateTime(date.year, date.month, date.day);

      if (startDay.isAfter(today)) {
        return 'Starts on $startDate';
      } else {
        return 'Started $startDate';
      }
    } catch (_) {
      return 'Started $startDate';
    }
  }

  Widget _buildProgramCard(ProgramModel program) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.2),
            theme.colorScheme.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Current Program',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            program.name,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatStartDateLabel(program.startDate),
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesSection(WorkoutState state) {
    final theme = Theme.of(context);
    final exercises = state.dailySummary?.exercises ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (exercises.isEmpty)
          _buildEmptyState()
        else
          ...exercises.map((exercise) => _ExerciseCard(exercise: exercise)),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            'No workouts logged',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to log your workout',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseEntry exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${exercise.sets.length} sets',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Sets
          if (exercise.sets.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  // Header row
                  Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          'Set',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Weight',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'Reps',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Set rows
                  ...exercise.sets.map((set) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${set.setNumber}',
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                set.weight != null
                                    ? '${set.weight} ${set.unit}'
                                    : '-',
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${set.reps}',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyLarge?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    set.completed
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: set.completed
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodySmall?.color,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
