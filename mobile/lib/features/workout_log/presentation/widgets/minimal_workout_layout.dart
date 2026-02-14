import 'package:flutter/material.dart';
import '../screens/active_workout_screen.dart';

/// Minimal workout layout: compact collapsible list with quick-complete.
/// Best for speed loggers doing high-volume training.
class MinimalWorkoutLayout extends StatefulWidget {
  final List<ExerciseLogState> exerciseLogs;
  final void Function(int exerciseIndex, int setIndex, double weight, int reps)
      onSetCompleted;
  final void Function(int exerciseIndex) onAddSet;

  const MinimalWorkoutLayout({
    super.key,
    required this.exerciseLogs,
    required this.onSetCompleted,
    required this.onAddSet,
  });

  @override
  State<MinimalWorkoutLayout> createState() => _MinimalWorkoutLayoutState();
}

class _MinimalWorkoutLayoutState extends State<MinimalWorkoutLayout> {
  /// Track which exercise is expanded. -1 means none.
  int _expandedIndex = 0;

  /// Controllers: [exerciseIndex][setIndex]
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
  void didUpdateWidget(covariant MinimalWorkoutLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.exerciseLogs.length,
      itemBuilder: (context, exerciseIndex) {
        final exerciseLog = widget.exerciseLogs[exerciseIndex];
        final exercise = exerciseLog.exercise;
        final completedSets =
            exerciseLog.sets.where((s) => s.isCompleted).length;
        final totalSets = exerciseLog.sets.length;
        final isExpanded = _expandedIndex == exerciseIndex;
        final allDone = completedSets == totalSets;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: allDone
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.dividerColor,
              ),
            ),
            child: Column(
              children: [
                // Collapsed header — always visible
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _expandedIndex =
                          isExpanded ? -1 : exerciseIndex;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Circular progress
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: totalSets > 0
                                    ? completedSets / totalSets
                                    : 0,
                                strokeWidth: 3,
                                backgroundColor:
                                    theme.dividerColor.withValues(alpha: 0.3),
                                color: allDone
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.7),
                              ),
                              if (allDone)
                                Icon(
                                  Icons.check,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Exercise name + progress text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  decoration: allDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                '$completedSets/$totalSets sets done',
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Expand/collapse icon
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded content
                if (isExpanded) ...[
                  const Divider(height: 1),
                  ...exerciseLog.sets.asMap().entries.map((entry) {
                    return _buildCompactSetRow(
                      theme,
                      exerciseIndex,
                      entry.key,
                      entry.value,
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton.icon(
                      onPressed: () => widget.onAddSet(exerciseIndex),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Set', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactSetRow(
    ThemeData theme,
    int exerciseIndex,
    int setIndex,
    SetLogState set,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: set.isCompleted
            ? theme.colorScheme.primary.withValues(alpha: 0.04)
            : null,
      ),
      child: Row(
        children: [
          // Set number badge
          Container(
            width: 24,
            height: 24,
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
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Weight input
          SizedBox(
            width: 70,
            child: TextField(
              controller: _weightControllers[exerciseIndex][setIndex],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              enabled: !set.isCompleted,
              decoration: InputDecoration(
                hintText: set.lastWeight?.round().toString() ?? '0',
                hintStyle: TextStyle(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                suffixText: 'lbs',
                suffixStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 11,
                ),
                filled: true,
                fillColor: set.isCompleted
                    ? theme.dividerColor.withValues(alpha: 0.3)
                    : theme.scaffoldBackgroundColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.5)),
                ),
              ),
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // "x" separator
          Text(
            'x',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),

          // Reps input
          SizedBox(
            width: 60,
            child: TextField(
              controller: _repsControllers[exerciseIndex][setIndex],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              enabled: !set.isCompleted,
              decoration: InputDecoration(
                hintText:
                    set.lastReps?.toString() ?? set.targetReps.toString(),
                hintStyle: TextStyle(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                suffixText: 'reps',
                suffixStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 11,
                ),
                filled: true,
                fillColor: set.isCompleted
                    ? theme.dividerColor.withValues(alpha: 0.3)
                    : theme.scaffoldBackgroundColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.5)),
                ),
              ),
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Spacer(),

          // Complete button
          set.isCompleted
              ? Icon(Icons.check_circle,
                  color: theme.colorScheme.primary, size: 28)
              : IconButton(
                  onPressed: () =>
                      _completeSet(exerciseIndex, setIndex),
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: theme.textTheme.bodySmall?.color,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
}
