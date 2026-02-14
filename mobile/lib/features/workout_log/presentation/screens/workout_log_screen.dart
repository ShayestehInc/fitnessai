import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';

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
        child: state.isLoading && state.programWeeks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(workoutStateProvider.notifier).loadInitialData(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: _buildHeader(theme, state),
                    ),

                    // Week tabs
                    SliverToBoxAdapter(
                      child: _buildWeekTabs(theme, state),
                    ),

                    // Workout cards
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: _buildWorkoutsList(theme, state),
                    ),

                    // Bottom spacing for buttons
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 140),
                    ),
                  ],
                ),
              ),
      ),
      bottomSheet: state.programWeeks.isNotEmpty
          ? _buildBottomActions(theme, state)
          : null,
    );
  }

  Widget _buildHeader(ThemeData theme, WorkoutState state) {
    final programName = state.activeProgram?.name ?? 'My Program';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logbook',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      programName,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push('/workout-calendar'),
                    icon: const Icon(Icons.calendar_month),
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  IconButton(
                    onPressed: () => _showProgramOptions(context),
                    icon: const Icon(Icons.more_vert),
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTabs(ThemeData theme, WorkoutState state) {
    if (state.programWeeks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 56,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: state.programWeeks.length,
        itemBuilder: (context, index) {
          final week = state.programWeeks[index];
          final isSelected = index == state.selectedWeekIndex;
          final completion = (week.completionPercentage * 100).round();

          return GestureDetector(
            onTap: () => ref.read(workoutStateProvider.notifier).selectWeek(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Week ${week.weekNumber}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completion%',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.textTheme.bodySmall?.color,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkoutsList(ThemeData theme, WorkoutState state) {
    final week = state.selectedWeek;
    if (week == null || week.workouts.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(theme, state),
      );
    }

    final workouts = week.workouts.where((w) => !w.isRestDay).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final workout = workouts[index];
          return _WorkoutCard(
            workout: workout,
            onTap: () => _startWorkout(context, workout),
          );
        },
        childCount: workouts.length,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, WorkoutState state) {
    // Determine which empty state to show
    final bool hasPrograms = state.programs.isNotEmpty;
    final bool hasActiveProgram = state.activeProgram != null;
    final bool hasEmptySchedule = hasActiveProgram && state.programWeeks.isEmpty;

    final String title;
    final String subtitle;
    final IconData icon;

    if (!hasPrograms) {
      title = 'No programs assigned';
      subtitle = 'Your trainer will assign you a program soon';
      icon = Icons.fitness_center;
    } else if (hasEmptySchedule) {
      title = 'Schedule not built yet';
      subtitle = "Your trainer hasn't built your schedule yet";
      icon = Icons.calendar_today;
    } else {
      title = 'No workouts this week';
      subtitle = 'Check other weeks or contact your trainer';
      icon = Icons.event_busy;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

  Widget _buildBottomActions(ThemeData theme, WorkoutState state) {
    final todaysWorkout = state.todaysWorkout;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start Today's Workout button
            if (todaysWorkout != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startWorkout(context, todaysWorkout),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start Today's Workout"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (todaysWorkout != null) const SizedBox(height: 12),

            // Secondary actions row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/ai-command'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Workout'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showProgramOptions(context),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context, ProgramWorkoutDay workout) {
    context.push('/active-workout', extra: workout);
  }

  void _showProgramOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.list_alt, color: theme.colorScheme.primary),
                title: const Text('View All Programs'),
                onTap: () {
                  context.pop();
                  context.push('/my-programs');
                },
              ),
              ListTile(
                leading: Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
                title: const Text('Switch Program'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Wait for the options sheet to fully close before opening switcher
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _showProgramSwitcher(this.context);
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                title: const Text('View Calendar'),
                onTap: () {
                  context.pop();
                  context.push('/workout-calendar');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProgramSwitcher(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.read(workoutStateProvider);
    final programs = state.programs;

    if (programs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No programs available to switch to')),
      );
      return;
    }

    if (programs.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You only have one program assigned')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Switch Program',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...programs.map((program) {
                final isActive = program.id == state.activeProgram?.id;
                return ListTile(
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.circle_outlined,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodySmall?.color,
                  ),
                  title: Text(
                    program.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(program.description.isNotEmpty
                      ? program.description
                      : 'Started ${program.startDate}'),
                  onTap: () {
                    if (!isActive) {
                      ref
                          .read(workoutStateProvider.notifier)
                          .switchProgram(program);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${program.name}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final ProgramWorkoutDay workout;
  final VoidCallback onTap;

  const _WorkoutCard({
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String statusLabel;
    Color statusColor;
    if (workout.isToday) {
      statusLabel = "Today's Workout";
      statusColor = theme.colorScheme.primary;
    } else if (workout.isCompleted) {
      statusLabel = 'Completed';
      statusColor = Colors.green;
    } else {
      statusLabel = 'Following Workout';
      statusColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: workout.isToday
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor,
            width: workout.isToday ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout image placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: _getMuscleGroupColor(workout.exercises.isNotEmpty
                    ? workout.exercises.first.muscleGroup
                    : 'other'),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Stack(
                children: [
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Muscle group icon
                  Center(
                    child: Icon(
                      _getMuscleGroupIcon(workout.exercises.isNotEmpty
                          ? workout.exercises.first.muscleGroup
                          : 'other'),
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Completed check
                  if (workout.isCompleted)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Workout info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${workout.exerciseCount} exercises  ~${workout.estimatedMinutes} min',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: workout.isToday
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.dividerColor.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      workout.isToday ? Icons.play_arrow : Icons.chevron_right,
                      color: workout.isToday
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return Colors.red.shade700;
      case 'back':
        return Colors.blue.shade700;
      case 'shoulders':
        return Colors.orange.shade700;
      case 'legs':
        return Colors.green.shade700;
      case 'biceps':
      case 'triceps':
      case 'arms':
        return Colors.purple.shade700;
      case 'core':
      case 'abs':
        return Colors.teal.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  IconData _getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.accessibility_new;
      case 'shoulders':
        return Icons.sports_gymnastics;
      case 'legs':
        return Icons.directions_run;
      case 'biceps':
      case 'triceps':
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
      case 'abs':
        return Icons.sports;
      default:
        return Icons.fitness_center;
    }
  }
}
