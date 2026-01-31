import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';
import '../../data/models/program_week_model.dart';
import '../providers/program_provider.dart';
import 'week_editor_screen.dart';

class ProgramBuilderScreen extends ConsumerStatefulWidget {
  final int? traineeId;
  final String? templateName;
  final int? durationWeeks;
  final String? difficulty;
  final String? goal;
  final List<String>? weeklySchedule;
  final DateTime? startDate;
  /// If provided, we're editing an existing template
  final int? existingTemplateId;
  /// Existing weeks data when editing
  final List<ProgramWeek>? existingWeeks;

  const ProgramBuilderScreen({
    super.key,
    this.traineeId,
    this.templateName,
    this.durationWeeks,
    this.difficulty,
    this.goal,
    this.weeklySchedule,
    this.startDate,
    this.existingTemplateId,
    this.existingWeeks,
  });

  @override
  ConsumerState<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  late ProgramBuilderState _programState;
  int _selectedWeekIndex = 0;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate ?? DateTime.now();
    _initializeProgram();
  }

  void _initializeProgram() {
    // If editing existing template with weeks data, use that
    if (widget.existingWeeks != null && widget.existingWeeks!.isNotEmpty) {
      _programState = ProgramBuilderState(
        name: widget.templateName ?? 'Custom Program',
        description: null,
        difficulty: widget.difficulty ?? 'intermediate',
        goal: widget.goal ?? 'build_muscle',
        durationWeeks: widget.existingWeeks!.length,
        weeks: widget.existingWeeks!,
      );
      return;
    }

    final weekCount = widget.durationWeeks ?? 4;
    final schedule = widget.weeklySchedule ?? ['Workout A', 'Rest', 'Workout B', 'Rest', 'Workout A', 'Rest', 'Rest'];

    // Create weeks with default exercises based on schedule
    final weeks = List.generate(weekCount, (weekIndex) {
      final days = List.generate(7, (dayIndex) {
        final dayName = schedule[dayIndex % schedule.length];
        final isRest = dayName == 'Rest';

        return WorkoutDay(
          name: dayName,
          isRestDay: isRest,
          exercises: isRest ? [] : _getDefaultExercisesForDay(dayName, weekIndex),
        );
      });

      return ProgramWeek(
        weekNumber: weekIndex + 1,
        title: weekIndex == weekCount - 1 && weekCount >= 4 ? 'Deload Week' : null,
        isDeload: weekIndex == weekCount - 1 && weekCount >= 4,
        intensityModifier: weekIndex == weekCount - 1 && weekCount >= 4 ? 0.6 : 1.0,
        volumeModifier: weekIndex == weekCount - 1 && weekCount >= 4 ? 0.6 : 1.0,
        days: days,
      );
    });

    _programState = ProgramBuilderState(
      name: widget.templateName ?? 'Custom Program',
      description: null,
      difficulty: widget.difficulty ?? 'intermediate',
      goal: widget.goal ?? 'build_muscle',
      durationWeeks: weekCount,
      weeks: weeks,
    );
  }

  List<WorkoutExercise> _getDefaultExercisesForDay(String dayName, int weekIndex) {
    // Progressive overload: increase reps or sets slightly each week
    final weekModifier = weekIndex; // 0-based
    final baseReps = 10 + (weekModifier ~/ 2); // Increase reps every 2 weeks
    final baseSets = 3 + (weekModifier ~/ 3); // Increase sets every 3 weeks

    switch (dayName.toLowerCase()) {
      case 'push':
        return [
          WorkoutExercise(exerciseId: 1, exerciseName: 'Barbell Bench Press', muscleGroup: 'chest', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 2, exerciseName: 'Incline Dumbbell Press', muscleGroup: 'chest', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 15, exerciseName: 'Overhead Press', muscleGroup: 'shoulders', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 16, exerciseName: 'Lateral Raises', muscleGroup: 'shoulders', sets: baseSets, reps: 12 + weekModifier),
          WorkoutExercise(exerciseId: 25, exerciseName: 'Tricep Pushdown', muscleGroup: 'arms', sets: baseSets, reps: 12 + weekModifier),
        ];
      case 'pull':
        return [
          WorkoutExercise(exerciseId: 30, exerciseName: 'Barbell Deadlift', muscleGroup: 'back', sets: baseSets, reps: baseReps - 2),
          WorkoutExercise(exerciseId: 31, exerciseName: 'Barbell Bent-Over Row', muscleGroup: 'back', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 32, exerciseName: 'Lat Pulldown', muscleGroup: 'back', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 40, exerciseName: 'Face Pulls', muscleGroup: 'shoulders', sets: baseSets, reps: 15 + weekModifier),
          WorkoutExercise(exerciseId: 45, exerciseName: 'Barbell Bicep Curl', muscleGroup: 'arms', sets: baseSets, reps: 12 + weekModifier),
        ];
      case 'legs':
        return [
          WorkoutExercise(exerciseId: 50, exerciseName: 'Barbell Back Squat', muscleGroup: 'legs', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 51, exerciseName: 'Romanian Deadlift', muscleGroup: 'legs', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 52, exerciseName: 'Leg Press', muscleGroup: 'legs', sets: baseSets, reps: 12 + weekModifier),
          WorkoutExercise(exerciseId: 53, exerciseName: 'Leg Curl', muscleGroup: 'legs', sets: baseSets, reps: 12 + weekModifier),
          WorkoutExercise(exerciseId: 54, exerciseName: 'Calf Raises', muscleGroup: 'legs', sets: 4, reps: 15 + weekModifier),
        ];
      case 'upper':
        return [
          WorkoutExercise(exerciseId: 1, exerciseName: 'Barbell Bench Press', muscleGroup: 'chest', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 31, exerciseName: 'Barbell Bent-Over Row', muscleGroup: 'back', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 15, exerciseName: 'Overhead Press', muscleGroup: 'shoulders', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 32, exerciseName: 'Lat Pulldown', muscleGroup: 'back', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 45, exerciseName: 'Barbell Bicep Curl', muscleGroup: 'arms', sets: baseSets, reps: 12),
          WorkoutExercise(exerciseId: 25, exerciseName: 'Tricep Pushdown', muscleGroup: 'arms', sets: baseSets, reps: 12),
        ];
      case 'lower':
        return [
          WorkoutExercise(exerciseId: 50, exerciseName: 'Barbell Back Squat', muscleGroup: 'legs', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 51, exerciseName: 'Romanian Deadlift', muscleGroup: 'legs', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 52, exerciseName: 'Leg Press', muscleGroup: 'legs', sets: baseSets, reps: 12 + weekModifier),
          WorkoutExercise(exerciseId: 55, exerciseName: 'Walking Lunges', muscleGroup: 'legs', sets: baseSets, reps: 12),
          WorkoutExercise(exerciseId: 53, exerciseName: 'Leg Curl', muscleGroup: 'legs', sets: baseSets, reps: 12 + weekModifier),
          WorkoutExercise(exerciseId: 54, exerciseName: 'Calf Raises', muscleGroup: 'legs', sets: 4, reps: 15),
        ];
      case 'full body':
      case 'workout a':
      case 'workout b':
      default:
        return [
          WorkoutExercise(exerciseId: 50, exerciseName: 'Barbell Back Squat', muscleGroup: 'legs', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 1, exerciseName: 'Barbell Bench Press', muscleGroup: 'chest', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 31, exerciseName: 'Barbell Bent-Over Row', muscleGroup: 'back', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 15, exerciseName: 'Overhead Press', muscleGroup: 'shoulders', sets: baseSets, reps: baseReps),
          WorkoutExercise(exerciseId: 51, exerciseName: 'Romanian Deadlift', muscleGroup: 'legs', sets: baseSets, reps: baseReps),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_programState.name),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _saveProgram,
                  child: const Text('Save'),
                ),
        ],
      ),
      body: Column(
        children: [
          // Start date selector (only show if assigning to trainee)
          if (widget.traineeId != null) _buildStartDateSelector(context),

          // Week selector tabs
          _buildWeekSelector(context),

          // Week content
          Expanded(
            child: _buildWeekContent(context, _programState.weeks[_selectedWeekIndex]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editWeek(_programState.weeks[_selectedWeekIndex]),
        icon: const Icon(Icons.edit),
        label: const Text('Edit Week'),
      ),
    );
  }

  Widget _buildStartDateSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Text(
                  _formatDate(_startDate),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _startDate = picked);
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildWeekSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _programState.weeks.length,
        itemBuilder: (context, index) {
          final week = _programState.weeks[index];
          final isSelected = index == _selectedWeekIndex;

          return GestureDetector(
            onTap: () => setState(() => _selectedWeekIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : week.isDeload
                        ? Colors.orange.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: week.isDeload && !isSelected
                    ? Border.all(color: Colors.orange)
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    'W${week.weekNumber}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (week.isDeload) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.trending_down,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.orange,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekContent(BuildContext context, ProgramWeek week) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week header card
          _buildWeekHeaderCard(context, week),

          const SizedBox(height: 20),

          // Quick actions
          _buildQuickActions(context, week),

          const SizedBox(height: 20),

          // Days list
          const Text(
            'Workout Days',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),

          ...week.days.asMap().entries.map((entry) =>
            _buildDayCard(context, entry.key, entry.value, week)),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildWeekHeaderCard(BuildContext context, ProgramWeek week) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: week.isDeload
              ? [Colors.orange.withValues(alpha: 0.1), Colors.orange.withValues(alpha: 0.05)]
              : [theme.colorScheme.primary.withValues(alpha: 0.1), theme.colorScheme.primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: week.isDeload
                  ? Colors.orange.withValues(alpha: 0.2)
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'W${week.weekNumber}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: week.isDeload ? Colors.orange : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  week.title ?? 'Week ${week.weekNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${week.totalWorkoutDays} workout days • ${week.totalExercises} exercises • ${week.totalSets} total sets',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                if (week.isDeload) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Deload: Reduced Volume & Intensity',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ProgramWeek week) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.content_copy,
            label: 'Copy to All',
            onTap: () => _copyToAllWeeks(week),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.trending_up,
            label: 'Add Volume',
            onTap: () => _adjustVolume(week, increase: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.trending_down,
            label: week.isDeload ? 'Remove Deload' : 'Mark Deload',
            color: Colors.orange,
            onTap: () => _toggleDeload(week),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color ?? theme.colorScheme.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color ?? theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, int index, WorkoutDay day, ProgramWeek week) {
    final theme = Theme.of(context);
    final dayLabel = 'Day ${index + 1}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: day.isRestDay ? Colors.grey.withValues(alpha: 0.3) : theme.dividerColor,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: day.isRestDay
                  ? Colors.grey.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              day.isRestDay ? Icons.bed : Icons.fitness_center,
              color: day.isRestDay ? Colors.grey : theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            dayLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            day.isRestDay
                ? 'Rest Day'
                : '${day.name} • ${day.exercises.length} exercises',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          children: day.isRestDay
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.self_improvement, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Text(
                          'Recovery & rest',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ]
              : [
                  ...day.exercises.map((exercise) => _buildExerciseRow(context, exercise, week, index)),
                  // Add Exercise button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddExerciseDialog(index),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Exercise'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildExerciseRow(BuildContext context, WorkoutExercise exercise, ProgramWeek week, int dayIndex) {
    final theme = Theme.of(context);
    // Apply modifiers for deload weeks
    final adjustedSets = (exercise.sets * week.volumeModifier).round();
    final adjustedReps = (exercise.reps * week.intensityModifier).round();
    final isInSuperset = exercise.isInSuperset;

    // Get superset position info
    final day = week.days[dayIndex];
    final exerciseIndex = day.exercises.indexOf(exercise);
    final isFirstInSuperset = isInSuperset &&
        (exerciseIndex == 0 || day.exercises[exerciseIndex - 1].supersetGroupId != exercise.supersetGroupId);

    return Container(
      margin: EdgeInsets.only(left: isInSuperset ? 8 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
          left: isInSuperset
              ? BorderSide(color: theme.colorScheme.secondary, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Superset indicator or exercise icon
          if (isInSuperset)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.link, size: 16, color: theme.colorScheme.secondary),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showEditExerciseDialog(exercise, dayIndex),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.exerciseName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (isFirstInSuperset)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SUPERSET',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    exercise.muscleGroup.replaceAll('_', ' ').split(' ').map((w) =>
                      w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Sets x Reps with edit button
          GestureDetector(
            onTap: () => _showEditExerciseDialog(exercise, dayIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isInSuperset
                    ? theme.colorScheme.secondary.withValues(alpha: 0.15)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '$adjustedSets × $adjustedReps',
                    style: TextStyle(
                      color: isInSuperset ? theme.colorScheme.secondary : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 14, color: isInSuperset ? theme.colorScheme.secondary : theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditExerciseDialog(WorkoutExercise exercise, int dayIndex) {
    final theme = Theme.of(context);
    int sets = exercise.sets;
    int reps = exercise.reps;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise.exerciseName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Replace button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showReplaceExerciseDialog(exercise, dayIndex);
                    },
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Replace exercise',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Remove button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _removeExercise(exercise, dayIndex);
                    },
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove exercise',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              Text(
                exercise.muscleGroup.replaceAll('_', ' ').split(' ').map((w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Sets slider
              Row(
                children: [
                  const SizedBox(width: 60, child: Text('Sets:')),
                  Expanded(
                    child: Slider(
                      value: sets.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      label: sets.toString(),
                      onChanged: (value) {
                        setModalState(() => sets = value.round());
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      sets.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              // Reps slider
              Row(
                children: [
                  const SizedBox(width: 60, child: Text('Reps:')),
                  Expanded(
                    child: Slider(
                      value: reps.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: reps.toString(),
                      onChanged: (value) {
                        setModalState(() => reps = value.round());
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      reps.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Apply buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _applyToThisWeek(exercise, sets, reps);
                        Navigator.pop(context);
                      },
                      child: const Text('This Week'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _applyToAllWeeks(exercise, sets, reps);
                        Navigator.pop(context);
                      },
                      child: const Text('All Weeks'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    _applyProgressiveOverload(exercise, sets, reps);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply with Progressive Overload (+1 rep/week)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Exercise library for selection
  static const List<Map<String, dynamic>> _exerciseLibrary = [
    // Chest
    {'id': 1, 'name': 'Barbell Bench Press', 'muscle': 'chest'},
    {'id': 2, 'name': 'Incline Dumbbell Press', 'muscle': 'chest'},
    {'id': 3, 'name': 'Dumbbell Flyes', 'muscle': 'chest'},
    {'id': 4, 'name': 'Cable Crossover', 'muscle': 'chest'},
    {'id': 5, 'name': 'Push-Ups', 'muscle': 'chest'},
    {'id': 6, 'name': 'Decline Bench Press', 'muscle': 'chest'},
    // Back
    {'id': 30, 'name': 'Barbell Deadlift', 'muscle': 'back'},
    {'id': 31, 'name': 'Barbell Bent-Over Row', 'muscle': 'back'},
    {'id': 32, 'name': 'Lat Pulldown', 'muscle': 'back'},
    {'id': 33, 'name': 'Seated Cable Row', 'muscle': 'back'},
    {'id': 34, 'name': 'Pull-Ups', 'muscle': 'back'},
    {'id': 35, 'name': 'T-Bar Row', 'muscle': 'back'},
    {'id': 36, 'name': 'Dumbbell Row', 'muscle': 'back'},
    // Shoulders
    {'id': 15, 'name': 'Overhead Press', 'muscle': 'shoulders'},
    {'id': 16, 'name': 'Lateral Raises', 'muscle': 'shoulders'},
    {'id': 17, 'name': 'Front Raises', 'muscle': 'shoulders'},
    {'id': 18, 'name': 'Rear Delt Flyes', 'muscle': 'shoulders'},
    {'id': 40, 'name': 'Face Pulls', 'muscle': 'shoulders'},
    {'id': 19, 'name': 'Arnold Press', 'muscle': 'shoulders'},
    // Legs
    {'id': 50, 'name': 'Barbell Back Squat', 'muscle': 'legs'},
    {'id': 51, 'name': 'Romanian Deadlift', 'muscle': 'legs'},
    {'id': 52, 'name': 'Leg Press', 'muscle': 'legs'},
    {'id': 53, 'name': 'Leg Curl', 'muscle': 'legs'},
    {'id': 54, 'name': 'Calf Raises', 'muscle': 'legs'},
    {'id': 55, 'name': 'Walking Lunges', 'muscle': 'legs'},
    {'id': 56, 'name': 'Leg Extension', 'muscle': 'legs'},
    {'id': 57, 'name': 'Bulgarian Split Squat', 'muscle': 'legs'},
    {'id': 58, 'name': 'Hip Thrust', 'muscle': 'legs'},
    // Arms
    {'id': 25, 'name': 'Tricep Pushdown', 'muscle': 'arms'},
    {'id': 45, 'name': 'Barbell Bicep Curl', 'muscle': 'arms'},
    {'id': 26, 'name': 'Skull Crushers', 'muscle': 'arms'},
    {'id': 27, 'name': 'Hammer Curls', 'muscle': 'arms'},
    {'id': 28, 'name': 'Preacher Curls', 'muscle': 'arms'},
    {'id': 29, 'name': 'Tricep Dips', 'muscle': 'arms'},
    // Core
    {'id': 60, 'name': 'Plank', 'muscle': 'core'},
    {'id': 61, 'name': 'Cable Crunches', 'muscle': 'core'},
    {'id': 62, 'name': 'Hanging Leg Raises', 'muscle': 'core'},
    {'id': 63, 'name': 'Russian Twists', 'muscle': 'core'},
    {'id': 64, 'name': 'Ab Wheel Rollout', 'muscle': 'core'},
  ];

  void _showAddExerciseDialog(int dayIndex) {
    _showExercisePicker(
      title: 'Add Exercise',
      onSelect: (exercise) => _addExerciseToDay(exercise, dayIndex),
    );
  }

  void _showReplaceExerciseDialog(WorkoutExercise oldExercise, int dayIndex) {
    _showExercisePicker(
      title: 'Replace ${oldExercise.exerciseName}',
      onSelect: (newExercise) => _replaceExercise(oldExercise, newExercise, dayIndex),
    );
  }

  void _showExercisePicker({
    required String title,
    required void Function(Map<String, dynamic> exercise) onSelect,
  }) {
    final theme = Theme.of(context);
    String searchQuery = '';
    String? selectedMuscle;

    final muscles = ['chest', 'back', 'shoulders', 'legs', 'arms', 'core'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredExercises = _exerciseLibrary.where((e) {
            final matchesSearch = searchQuery.isEmpty ||
                e['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
            final matchesMuscle = selectedMuscle == null || e['muscle'] == selectedMuscle;
            return matchesSearch && matchesMuscle;
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
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
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search exercises...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          setModalState(() => searchQuery = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      // Muscle group filters
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: selectedMuscle == null,
                              onSelected: (_) {
                                setModalState(() => selectedMuscle = null);
                              },
                            ),
                            const SizedBox(width: 8),
                            ...muscles.map((muscle) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(muscle[0].toUpperCase() + muscle.substring(1)),
                                selected: selectedMuscle == muscle,
                                onSelected: (_) {
                                  setModalState(() => selectedMuscle = muscle);
                                },
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(exercise['name'] as String),
                        subtitle: Text(
                          (exercise['muscle'] as String)[0].toUpperCase() +
                              (exercise['muscle'] as String).substring(1),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(exercise);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addExerciseToDay(Map<String, dynamic> exerciseData, int dayIndex) {
    setState(() {
      final weekIndex = _selectedWeekIndex;
      final updatedWeeks = List<ProgramWeek>.from(_programState.weeks);
      final week = updatedWeeks[weekIndex];
      final day = week.days[dayIndex];

      final newExercise = WorkoutExercise(
        exerciseId: exerciseData['id'] as int,
        exerciseName: exerciseData['name'] as String,
        muscleGroup: exerciseData['muscle'] as String,
        sets: 3,
        reps: 10,
      );

      final updatedDays = List<WorkoutDay>.from(week.days);
      updatedDays[dayIndex] = day.copyWith(
        exercises: [...day.exercises, newExercise],
      );

      updatedWeeks[weekIndex] = week.copyWith(days: updatedDays);
      _programState = _programState.copyWith(weeks: updatedWeeks);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${exerciseData['name']}')),
    );
  }

  void _replaceExercise(WorkoutExercise oldExercise, Map<String, dynamic> newExerciseData, int dayIndex) {
    setState(() {
      final weekIndex = _selectedWeekIndex;
      final updatedWeeks = List<ProgramWeek>.from(_programState.weeks);
      final week = updatedWeeks[weekIndex];

      final updatedDays = week.days.asMap().entries.map((entry) {
        if (entry.key != dayIndex) return entry.value;

        final day = entry.value;
        final updatedExercises = day.exercises.map((e) {
          if (e.exerciseId == oldExercise.exerciseId) {
            return WorkoutExercise(
              exerciseId: newExerciseData['id'] as int,
              exerciseName: newExerciseData['name'] as String,
              muscleGroup: newExerciseData['muscle'] as String,
              sets: e.sets,
              reps: e.reps,
            );
          }
          return e;
        }).toList();
        return day.copyWith(exercises: updatedExercises);
      }).toList();

      updatedWeeks[weekIndex] = week.copyWith(days: updatedDays);
      _programState = _programState.copyWith(weeks: updatedWeeks);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Replaced with ${newExerciseData['name']}')),
    );
  }

  void _removeExercise(WorkoutExercise exercise, int dayIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: Text('Remove "${exercise.exerciseName}" from this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final weekIndex = _selectedWeekIndex;
                final updatedWeeks = List<ProgramWeek>.from(_programState.weeks);
                final week = updatedWeeks[weekIndex];
                final day = week.days[dayIndex];

                final updatedDays = List<WorkoutDay>.from(week.days);
                updatedDays[dayIndex] = day.copyWith(
                  exercises: day.exercises.where((e) => e.exerciseId != exercise.exerciseId).toList(),
                );

                updatedWeeks[weekIndex] = week.copyWith(days: updatedDays);
                _programState = _programState.copyWith(weeks: updatedWeeks);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed ${exercise.exerciseName}')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _applyToThisWeek(WorkoutExercise exercise, int sets, int reps) {
    setState(() {
      final weekIndex = _selectedWeekIndex;
      final updatedWeeks = List<ProgramWeek>.from(_programState.weeks);
      final week = updatedWeeks[weekIndex];

      final updatedDays = week.days.map((day) {
        final updatedExercises = day.exercises.map((e) {
          if (e.exerciseId == exercise.exerciseId) {
            return e.copyWith(sets: sets, reps: reps);
          }
          return e;
        }).toList();
        return day.copyWith(exercises: updatedExercises);
      }).toList();

      updatedWeeks[weekIndex] = week.copyWith(days: updatedDays);
      _programState = _programState.copyWith(weeks: updatedWeeks);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updated for this week')),
    );
  }

  void _applyToAllWeeks(WorkoutExercise exercise, int sets, int reps) {
    setState(() {
      final updatedWeeks = _programState.weeks.map((week) {
        final updatedDays = week.days.map((day) {
          final updatedExercises = day.exercises.map((e) {
            if (e.exerciseId == exercise.exerciseId) {
              return e.copyWith(sets: sets, reps: reps);
            }
            return e;
          }).toList();
          return day.copyWith(exercises: updatedExercises);
        }).toList();
        return week.copyWith(days: updatedDays);
      }).toList();

      _programState = _programState.copyWith(weeks: updatedWeeks);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updated for all weeks')),
    );
  }

  void _applyProgressiveOverload(WorkoutExercise exercise, int sets, int reps) {
    setState(() {
      final updatedWeeks = _programState.weeks.asMap().entries.map((entry) {
        final weekIndex = entry.key;
        final week = entry.value;

        // Increase reps by 1 each week (or reset to base + 2 sets if reps > 15)
        int weekReps = reps + weekIndex;
        int weekSets = sets;

        if (weekReps > 15) {
          weekReps = reps;
          weekSets = sets + 1;
        }

        // Apply deload modifier
        if (week.isDeload) {
          weekReps = (weekReps * 0.6).round();
          weekSets = (weekSets * 0.6).round();
        }

        final updatedDays = week.days.map((day) {
          final updatedExercises = day.exercises.map((e) {
            if (e.exerciseId == exercise.exerciseId) {
              return e.copyWith(sets: weekSets, reps: weekReps);
            }
            return e;
          }).toList();
          return day.copyWith(exercises: updatedExercises);
        }).toList();
        return week.copyWith(days: updatedDays);
      }).toList();

      _programState = _programState.copyWith(weeks: updatedWeeks);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Applied progressive overload across all weeks')),
    );
  }

  void _copyToAllWeeks(ProgramWeek sourceWeek) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copy Week'),
        content: const Text('Copy this week\'s workout structure to all other weeks? This will overwrite existing exercises.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final updatedWeeks = _programState.weeks.map((week) {
                  if (week.weekNumber == sourceWeek.weekNumber) return week;
                  return week.copyWith(
                    days: sourceWeek.days,
                    isDeload: week.isDeload, // Preserve deload status
                  );
                }).toList();
                _programState = _programState.copyWith(weeks: updatedWeeks);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to all weeks')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _adjustVolume(ProgramWeek week, {required bool increase}) {
    setState(() {
      final weekIndex = _selectedWeekIndex;
      final updatedWeeks = List<ProgramWeek>.from(_programState.weeks);

      final updatedDays = week.days.map((day) {
        final updatedExercises = day.exercises.map((e) {
          return e.copyWith(
            sets: increase ? e.sets + 1 : (e.sets > 1 ? e.sets - 1 : 1),
          );
        }).toList();
        return day.copyWith(exercises: updatedExercises);
      }).toList();

      updatedWeeks[weekIndex] = week.copyWith(days: updatedDays);
      _programState = _programState.copyWith(weeks: updatedWeeks);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(increase ? 'Added 1 set to all exercises' : 'Removed 1 set from all exercises')),
    );
  }

  void _toggleDeload(ProgramWeek week) {
    setState(() {
      final weekIndex = _selectedWeekIndex;
      final updatedWeeks = List<ProgramWeek>.from(_programState.weeks);

      updatedWeeks[weekIndex] = week.copyWith(
        isDeload: !week.isDeload,
        title: !week.isDeload ? 'Deload Week' : null,
        intensityModifier: !week.isDeload ? 0.6 : 1.0,
        volumeModifier: !week.isDeload ? 0.6 : 1.0,
      );

      _programState = _programState.copyWith(weeks: updatedWeeks);
    });
  }

  void _editWeek(ProgramWeek week) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeekEditorScreen(
          week: week,
          onSave: (updatedWeek) {
            setState(() {
              final updatedWeeks = List<ProgramWeek>.from(_programState.weeks);
              updatedWeeks[_selectedWeekIndex] = updatedWeek;
              _programState = _programState.copyWith(weeks: updatedWeeks);
            });
          },
          onApplySupersetToAllWeeks: (dayIndex, exerciseNames, groupId) {
            setState(() {
              final updatedWeeks = List<ProgramWeek>.from(_programState.weeks);

              // Apply superset to all weeks (except current which is handled by onSave)
              for (int weekIndex = 0; weekIndex < updatedWeeks.length; weekIndex++) {
                if (weekIndex == _selectedWeekIndex) continue; // Skip current week

                final week = updatedWeeks[weekIndex];
                if (dayIndex >= week.days.length) continue;

                final day = week.days[dayIndex];
                final updatedExercises = List<WorkoutExercise>.from(day.exercises);

                // Find exercises by name and apply superset groupId
                for (int i = 0; i < updatedExercises.length; i++) {
                  if (exerciseNames.contains(updatedExercises[i].exerciseName)) {
                    updatedExercises[i] = updatedExercises[i].copyWith(supersetGroupId: groupId);
                  }
                }

                final updatedDays = List<WorkoutDay>.from(week.days);
                updatedDays[dayIndex] = day.copyWith(exercises: updatedExercises);
                updatedWeeks[weekIndex] = week.copyWith(days: updatedDays);
              }

              _programState = _programState.copyWith(weeks: updatedWeeks);
            });
          },
        ),
      ),
    );
  }

  bool _isSaving = false;

  Future<void> _saveProgram() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Build schedule template from the program state using model's toJson()
      final scheduleTemplate = _programState.weeks.map((week) => week.toJson()).toList();

      int templateId;

      // Check if we're updating an existing template or creating a new one
      if (widget.existingTemplateId != null) {
        // Update existing template
        await apiClient.dio.patch(
          '${ApiConstants.programTemplates}${widget.existingTemplateId}/',
          data: {
            'name': _programState.name,
            'description': _programState.description ?? '',
            'duration_weeks': _programState.durationWeeks,
            'difficulty_level': _programState.difficulty,
            'goal_type': _programState.goal,
            'schedule_template': scheduleTemplate,
          },
        );
        templateId = widget.existingTemplateId!;
      } else {
        // Create new program template
        final templateResponse = await apiClient.dio.post(
          ApiConstants.programTemplates,
          data: {
            'name': _programState.name,
            'description': _programState.description ?? '',
            'duration_weeks': _programState.durationWeeks,
            'difficulty_level': _programState.difficulty,
            'goal_type': _programState.goal,
            'schedule_template': scheduleTemplate,
            'is_public': false,
          },
        );
        templateId = templateResponse.data['id'] as int;
      }

      // Step 2: If we have a traineeId, assign the template to the trainee
      if (widget.traineeId != null) {
        // End current program if one exists (trainee can only have one active program)
        final trainee = ref.read(traineeDetailProvider(widget.traineeId!)).valueOrNull;
        if (trainee != null && trainee.programs.isNotEmpty) {
          final currentProgram = trainee.programs.first;
          await apiClient.dio.delete(ApiConstants.programDetail(currentProgram.id));
        }

        // Assign the new program
        await apiClient.dio.post(
          ApiConstants.assignProgramTemplate(templateId),
          data: {
            'trainee_id': widget.traineeId,
            'start_date': _formatDate(_startDate),
          },
        );

        if (mounted) {
          // Invalidate providers to refresh the data across all screens
          ref.invalidate(traineeDetailProvider(widget.traineeId!));
          ref.invalidate(traineesProvider);
          ref.invalidate(trainerStatsProvider);
          ref.invalidate(trainerProgramsProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Program saved and assigned successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Pop back to trainee detail screen (pop twice: builder -> assign -> detail)
          final navigator = Navigator.of(context);
          navigator.pop(); // Pop ProgramBuilderScreen
          navigator.pop(); // Pop AssignProgramScreen
        }
      } else {
        // Just saving as a template without assigning
        if (mounted) {
          // Invalidate template providers to refresh the list
          ref.invalidate(programTemplatesProvider);
          ref.invalidate(myTemplatesProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Program template saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save program: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
