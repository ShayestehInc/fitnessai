import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/program_week_model.dart';
import 'week_editor_screen.dart';

class ProgramBuilderScreen extends ConsumerStatefulWidget {
  final String? templateName;
  final int? durationWeeks;
  final String? difficulty;
  final String? goal;
  final List<String>? weeklySchedule;

  const ProgramBuilderScreen({
    super.key,
    this.templateName,
    this.durationWeeks,
    this.difficulty,
    this.goal,
    this.weeklySchedule,
  });

  @override
  ConsumerState<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  late ProgramBuilderState _programState;
  int _selectedWeekIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeProgram();
  }

  void _initializeProgram() {
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
          TextButton(
            onPressed: _saveProgram,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Week selector tabs
          _buildWeekSelector(),

          // Week content
          Expanded(
            child: _buildWeekContent(_programState.weeks[_selectedWeekIndex]),
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

  Widget _buildWeekSelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
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
                    ? AppTheme.primary
                    : week.isDeload
                        ? Colors.orange.withOpacity(0.1)
                        : AppTheme.muted,
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

  Widget _buildWeekContent(ProgramWeek week) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week header card
          _buildWeekHeaderCard(week),

          const SizedBox(height: 20),

          // Quick actions
          _buildQuickActions(week),

          const SizedBox(height: 20),

          // Days list
          const Text(
            'Workout Days',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),

          ...week.days.asMap().entries.map((entry) =>
            _buildDayCard(entry.key, entry.value, week)),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildWeekHeaderCard(ProgramWeek week) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: week.isDeload
              ? [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)]
              : [AppTheme.primary.withOpacity(0.1), AppTheme.primary.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: week.isDeload
                  ? Colors.orange.withOpacity(0.2)
                  : AppTheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'W${week.weekNumber}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: week.isDeload ? Colors.orange : AppTheme.primary,
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
                      color: Colors.orange.withOpacity(0.2),
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

  Widget _buildQuickActions(ProgramWeek week) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.content_copy,
            label: 'Copy to All',
            onTap: () => _copyToAllWeeks(week),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.trending_up,
            label: 'Add Volume',
            onTap: () => _adjustVolume(week, increase: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.trending_down,
            label: week.isDeload ? 'Remove Deload' : 'Mark Deload',
            color: Colors.orange,
            onTap: () => _toggleDeload(week),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: (color ?? AppTheme.primary).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color ?? AppTheme.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color ?? AppTheme.primary,
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

  Widget _buildDayCard(int index, WorkoutDay day, ProgramWeek week) {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: day.isRestDay ? Colors.grey.withOpacity(0.3) : AppTheme.border,
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
                  ? Colors.grey.withOpacity(0.1)
                  : AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              day.isRestDay ? Icons.bed : Icons.fitness_center,
              color: day.isRestDay ? Colors.grey : AppTheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            dayNames[index],
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
              : day.exercises.map((exercise) => _buildExerciseRow(exercise, week)).toList(),
        ),
      ),
    );
  }

  Widget _buildExerciseRow(WorkoutExercise exercise, ProgramWeek week) {
    // Apply modifiers for deload weeks
    final adjustedSets = (exercise.sets * week.volumeModifier).round();
    final adjustedReps = (exercise.reps * week.intensityModifier).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.muted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  exercise.muscleGroup.replaceAll('_', ' ').split(' ').map((w) =>
                    w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          // Sets x Reps with edit button
          GestureDetector(
            onTap: () => _showEditExerciseDialog(exercise),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '$adjustedSets × $adjustedReps',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 14, color: AppTheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditExerciseDialog(WorkoutExercise exercise) {
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
        ),
      ),
    );
  }

  void _saveProgram() {
    // TODO: Save to API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Program saved! (Backend integration coming soon)')),
    );
    context.pop();
  }
}
