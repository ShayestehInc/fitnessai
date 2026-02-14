import 'package:flutter/material.dart';
import '../screens/active_workout_screen.dart';

/// Classic workout layout: all exercises in a scrollable list with full sets tables.
/// Best for experienced lifters who want an overview of their entire workout.
class ClassicWorkoutLayout extends StatefulWidget {
  final List<ExerciseLogState> exerciseLogs;
  final void Function(int exerciseIndex, int setIndex, double weight, int reps)
      onSetCompleted;
  final void Function(int exerciseIndex) onAddSet;

  const ClassicWorkoutLayout({
    super.key,
    required this.exerciseLogs,
    required this.onSetCompleted,
    required this.onAddSet,
  });

  @override
  State<ClassicWorkoutLayout> createState() => _ClassicWorkoutLayoutState();
}

class _ClassicWorkoutLayoutState extends State<ClassicWorkoutLayout> {
  /// Controllers for each exercise's set inputs: [exerciseIndex][setIndex]
  late List<List<TextEditingController>> _weightControllers;
  late List<List<TextEditingController>> _repsControllers;

  @override
  void initState() {
    super.initState();
    _initAllControllers();
  }

  void _initAllControllers() {
    _weightControllers = widget.exerciseLogs.map((log) {
      return log.sets.map((set) {
        return TextEditingController(text: set.weight?.toString() ?? '');
      }).toList();
    }).toList();

    _repsControllers = widget.exerciseLogs.map((log) {
      return log.sets.map((set) {
        return TextEditingController(text: set.reps?.toString() ?? '');
      }).toList();
    }).toList();
  }

  @override
  void didUpdateWidget(covariant ClassicWorkoutLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers if sets were added
    for (int i = 0; i < widget.exerciseLogs.length; i++) {
      final sets = widget.exerciseLogs[i].sets;
      while (_weightControllers[i].length < sets.length) {
        final newSet = sets[_weightControllers[i].length];
        _weightControllers[i].add(
          TextEditingController(text: newSet.weight?.toString() ?? ''),
        );
        _repsControllers[i].add(
          TextEditingController(text: newSet.reps?.toString() ?? ''),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final list in _weightControllers) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final list in _repsControllers) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.exerciseLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, exerciseIndex) {
        final exerciseLog = widget.exerciseLogs[exerciseIndex];
        final exercise = exerciseLog.exercise;
        final completedSets =
            exerciseLog.sets.where((s) => s.isCompleted).length;

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${exercise.targetSets} sets x ${exercise.targetReps} reps',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: completedSets == exerciseLog.sets.length
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.dividerColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$completedSets/${exerciseLog.sets.length}',
                        style: TextStyle(
                          color: completedSets == exerciseLog.sets.length
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodySmall?.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Sets table header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _headerCell(theme, 'SET', 50),
                    _headerCell(theme, 'PREVIOUS', 80),
                    Expanded(
                      child: Text(
                        'LBS',
                        style: _headerStyle(theme),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'REPS',
                        style: _headerStyle(theme),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Set rows
              ...exerciseLog.sets.asMap().entries.map((entry) {
                return _buildSetRow(
                    theme, exerciseIndex, entry.key, entry.value);
              }),

              // Add set button
              Center(
                child: TextButton.icon(
                  onPressed: () => widget.onAddSet(exerciseIndex),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Set'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerCell(ThemeData theme, String text, double width) {
    return SizedBox(
      width: width,
      child: Text(text, style: _headerStyle(theme)),
    );
  }

  TextStyle _headerStyle(ThemeData theme) {
    return TextStyle(
      color: theme.textTheme.bodySmall?.color,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildSetRow(
    ThemeData theme,
    int exerciseIndex,
    int setIndex,
    SetLogState set,
  ) {
    final previousText = set.lastWeight != null && set.lastReps != null
        ? '${set.lastWeight!.round()} x ${set.lastReps}'
        : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: set.isCompleted
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : null,
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 50,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: set.isCompleted
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${set.setNumber}',
                  style: TextStyle(
                    color: set.isCompleted
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          // Previous
          SizedBox(
            width: 80,
            child: Text(
              previousText,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 13,
              ),
            ),
          ),

          // Weight input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _weightControllers[exerciseIndex][setIndex],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                enabled: !set.isCompleted,
                decoration: _inputDecoration(
                  theme,
                  hintText: set.lastWeight?.round().toString() ?? '0',
                  isCompleted: set.isCompleted,
                ),
                style: _inputTextStyle(theme),
              ),
            ),
          ),

          // Reps input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _repsControllers[exerciseIndex][setIndex],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                enabled: !set.isCompleted,
                decoration: _inputDecoration(
                  theme,
                  hintText:
                      set.lastReps?.toString() ?? set.targetReps.toString(),
                  isCompleted: set.isCompleted,
                ),
                style: _inputTextStyle(theme),
              ),
            ),
          ),

          // Complete button
          SizedBox(
            width: 48,
            child: set.isCompleted
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : IconButton(
                    onPressed: () => _completeSet(exerciseIndex, setIndex),
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _completeSet(int exerciseIndex, int setIndex) {
    final weightText = _weightControllers[exerciseIndex][setIndex].text;
    final repsText = _repsControllers[exerciseIndex][setIndex].text;
    final set = widget.exerciseLogs[exerciseIndex].sets[setIndex];

    final weight = double.tryParse(weightText) ?? set.lastWeight ?? 0;
    final reps = int.tryParse(repsText) ?? set.lastReps ?? set.targetReps;

    if (weightText.isEmpty) {
      _weightControllers[exerciseIndex][setIndex].text =
          weight.round().toString();
    }
    if (repsText.isEmpty) {
      _repsControllers[exerciseIndex][setIndex].text = reps.toString();
    }

    widget.onSetCompleted(exerciseIndex, setIndex, weight, reps);
  }

  InputDecoration _inputDecoration(
    ThemeData theme, {
    required String hintText,
    required bool isCompleted,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: isCompleted
          ? theme.dividerColor.withValues(alpha: 0.3)
          : theme.scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
    );
  }

  TextStyle _inputTextStyle(ThemeData theme) {
    return TextStyle(
      color: theme.textTheme.bodyLarge?.color,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );
  }
}
