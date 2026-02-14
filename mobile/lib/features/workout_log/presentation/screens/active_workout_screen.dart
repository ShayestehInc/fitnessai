import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';
import '../widgets/classic_workout_layout.dart';
import '../widgets/minimal_workout_layout.dart';
import 'readiness_survey_screen.dart';
import 'post_workout_survey_screen.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final ProgramWorkoutDay workout;

  const ActiveWorkoutScreen({
    super.key,
    required this.workout,
  });

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  // Workout phase
  WorkoutPhase _phase = WorkoutPhase.readinessSurvey;

  // Layout type — fetched once at init, cached for the session
  String _layoutType = 'classic';

  // Exercise logging state
  late List<ExerciseLogState> _exerciseLogs;
  int _currentExerciseIndex = 0;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  final Stopwatch _workoutStopwatch = Stopwatch();
  Timer? _workoutTimer;
  String _workoutDuration = '00:00';

  // Survey data
  ReadinessSurveyData? _readinessSurveyData;

  @override
  void initState() {
    super.initState();
    _initializeExerciseLogs();
    _fetchLayoutConfig();
  }

  Future<void> _fetchLayoutConfig() async {
    final repository = ref.read(workoutRepositoryProvider);
    final config = await repository.getMyLayout();
    if (mounted) {
      setState(() {
        _layoutType = config.layoutType;
      });
    }
  }

  void _initializeExerciseLogs() {
    _exerciseLogs = widget.workout.exercises.map((exercise) {
      return ExerciseLogState(
        exercise: exercise,
        sets: List.generate(
          exercise.targetSets,
          (index) => SetLogState(
            setNumber: index + 1,
            targetReps: exercise.targetReps,
            lastWeight: exercise.lastWeight,
            lastReps: exercise.lastReps,
          ),
        ),
      );
    }).toList();
  }

  void _startWorkoutTimer() {
    _workoutStopwatch.start();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          final duration = _workoutStopwatch.elapsed;
          final minutes = duration.inMinutes.toString().padLeft(2, '0');
          final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
          _workoutDuration = '$minutes:$seconds';
        });
      }
    });
  }

  void _startRestTimer(int seconds) {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _restSecondsRemaining--;
          if (_restSecondsRemaining <= 0) {
            _isResting = false;
            timer.cancel();
          }
        });
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _workoutTimer?.cancel();
    _workoutStopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case WorkoutPhase.readinessSurvey:
        return ReadinessSurveyScreen(
          workout: widget.workout,
          onSkip: () {
            setState(() => _phase = WorkoutPhase.workout);
            _startWorkoutTimer();
          },
          onComplete: (data) {
            _readinessSurveyData = data;
            setState(() => _phase = WorkoutPhase.workout);
            _startWorkoutTimer();
            // Submit readiness survey to backend
            _submitReadinessSurvey(data);
          },
        );
      case WorkoutPhase.workout:
        return _buildWorkoutScreen();
      case WorkoutPhase.postSurvey:
        return PostWorkoutSurveyScreen(
          workout: widget.workout,
          workoutDuration: _workoutDuration,
          setsCompleted: _exerciseLogs.fold<int>(
            0,
            (sum, log) => sum + log.sets.where((s) => s.isCompleted).length,
          ),
          totalSets: _exerciseLogs.fold<int>(
            0,
            (sum, log) => sum + log.sets.length,
          ),
          onComplete: (data) {
            _submitPostWorkoutSurvey(data);
            context.pop();
          },
        );
    }
  }

  Widget _buildWorkoutScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: Column(
          children: [
            Text(
              widget.workout.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _workoutDuration,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: Text(
              'Finish',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(theme),

          // Rest timer overlay
          if (_isResting) _buildRestTimer(theme),

          // Exercise content
          Expanded(
            child: _buildExerciseContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    final completedSets = _exerciseLogs.fold<int>(
      0,
      (sum, log) => sum + log.sets.where((s) => s.isCompleted).length,
    );
    final totalSets = _exerciseLogs.fold<int>(
      0,
      (sum, log) => sum + log.sets.length,
    );
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise ${_currentExerciseIndex + 1} of ${_exerciseLogs.length}',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 13,
                ),
              ),
              Text(
                '$completedSets / $totalSets sets',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.dividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest Time',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_restSecondsRemaining seconds remaining',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _skipRest,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseContent(ThemeData theme) {
    switch (_layoutType) {
      case 'card':
        return PageView.builder(
          itemCount: _exerciseLogs.length,
          onPageChanged: (index) {
            setState(() => _currentExerciseIndex = index);
          },
          itemBuilder: (context, index) {
            return _ExerciseCard(
              exerciseLog: _exerciseLogs[index],
              onSetCompleted: (setIndex, weight, reps) {
                _completeSet(index, setIndex, weight, reps);
              },
              onAddSet: () => _addSet(index),
            );
          },
        );
      case 'minimal':
        return MinimalWorkoutLayout(
          exerciseLogs: _exerciseLogs,
          onSetCompleted: (exerciseIndex, setIndex, weight, reps) {
            _completeSet(exerciseIndex, setIndex, weight, reps);
          },
          onAddSet: (exerciseIndex) => _addSet(exerciseIndex),
        );
      case 'classic':
      default:
        return ClassicWorkoutLayout(
          exerciseLogs: _exerciseLogs,
          onSetCompleted: (exerciseIndex, setIndex, weight, reps) {
            _completeSet(exerciseIndex, setIndex, weight, reps);
          },
          onAddSet: (exerciseIndex) => _addSet(exerciseIndex),
        );
    }
  }

  void _completeSet(int exerciseIndex, int setIndex, double weight, int reps) {
    setState(() {
      _exerciseLogs[exerciseIndex].sets[setIndex] = _exerciseLogs[exerciseIndex]
          .sets[setIndex]
          .copyWith(
            weight: weight,
            reps: reps,
            isCompleted: true,
          );
    });

    // Start rest timer
    final restSeconds = _exerciseLogs[exerciseIndex].exercise.restSeconds ?? 90;
    _startRestTimer(restSeconds);
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final currentSets = _exerciseLogs[exerciseIndex].sets;
      final lastSet = currentSets.isNotEmpty ? currentSets.last : null;
      _exerciseLogs[exerciseIndex].sets.add(SetLogState(
        setNumber: currentSets.length + 1,
        targetReps: _exerciseLogs[exerciseIndex].exercise.targetReps,
        lastWeight: lastSet?.weight ?? _exerciseLogs[exerciseIndex].exercise.lastWeight,
        lastReps: lastSet?.reps ?? _exerciseLogs[exerciseIndex].exercise.lastReps,
      ));
    });
  }

  void _finishWorkout() {
    _workoutStopwatch.stop();
    setState(() => _phase = WorkoutPhase.postSurvey);
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Workout?'),
        content: const Text('Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              context.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReadinessSurvey(ReadinessSurveyData data) async {
    final repository = ref.read(workoutRepositoryProvider);
    await repository.submitReadinessSurvey(
      workoutName: widget.workout.name,
      surveyData: data.toJson(),
    );
  }

  Future<void> _submitPostWorkoutSurvey(PostWorkoutSurveyData data) async {
    final repository = ref.read(workoutRepositoryProvider);

    // Prepare workout summary
    final workoutSummary = {
      'workout_name': widget.workout.name,
      'duration': _workoutDuration,
      'exercises': _exerciseLogs.map((log) => {
        'exercise_name': log.exercise.name,
        'sets': log.sets.map((set) => {
          'set_number': set.setNumber,
          'weight': set.weight,
          'reps': set.reps,
          'completed': set.isCompleted,
        }).toList(),
      }).toList(),
    };

    await repository.submitPostWorkoutSurvey(
      workoutSummary: workoutSummary,
      surveyData: data.toJson(),
      readinessSurvey: _readinessSurveyData?.toJson(),
    );
  }
}

enum WorkoutPhase {
  readinessSurvey,
  workout,
  postSurvey,
}

class ExerciseLogState {
  final ProgramExercise exercise;
  List<SetLogState> sets;

  ExerciseLogState({required this.exercise, required this.sets});
}

class SetLogState {
  final int setNumber;
  final int targetReps;
  final double? lastWeight;
  final int? lastReps;
  double? weight;
  int? reps;
  bool isCompleted;

  SetLogState({
    required this.setNumber,
    required this.targetReps,
    this.lastWeight,
    this.lastReps,
    this.weight,
    this.reps,
    this.isCompleted = false,
  });

  SetLogState copyWith({
    int? setNumber,
    int? targetReps,
    double? lastWeight,
    int? lastReps,
    double? weight,
    int? reps,
    bool? isCompleted,
  }) {
    return SetLogState(
      setNumber: setNumber ?? this.setNumber,
      targetReps: targetReps ?? this.targetReps,
      lastWeight: lastWeight ?? this.lastWeight,
      lastReps: lastReps ?? this.lastReps,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final ExerciseLogState exerciseLog;
  final Function(int setIndex, double weight, int reps) onSetCompleted;
  final VoidCallback onAddSet;

  const _ExerciseCard({
    required this.exerciseLog,
    required this.onSetCompleted,
    required this.onAddSet,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late List<TextEditingController> _weightControllers;
  late List<TextEditingController> _repsControllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _weightControllers = widget.exerciseLog.sets.map((set) {
      return TextEditingController(
        text: set.weight?.toString() ?? '',
      );
    }).toList();
    _repsControllers = widget.exerciseLog.sets.map((set) {
      return TextEditingController(
        text: set.reps?.toString() ?? '',
      );
    }).toList();
  }

  @override
  void didUpdateWidget(covariant _ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Add new controllers if sets were added
    while (_weightControllers.length < widget.exerciseLog.sets.length) {
      final newSet = widget.exerciseLog.sets[_weightControllers.length];
      _weightControllers.add(TextEditingController(
        text: newSet.weight?.toString() ?? '',
      ));
      _repsControllers.add(TextEditingController(
        text: newSet.reps?.toString() ?? '',
      ));
    }
  }

  @override
  void dispose() {
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    for (final controller in _repsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = widget.exerciseLog.exercise;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header with video thumbnail
          _buildExerciseHeader(theme, exercise),
          const SizedBox(height: 20),

          // Sets table
          _buildSetsTable(theme),
          const SizedBox(height: 12),

          // Add set button
          Center(
            child: TextButton.icon(
              onPressed: widget.onAddSet,
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
            ),
          ),

          // Exercise notes
          if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exercise.notes!,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(ThemeData theme, ProgramExercise exercise) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          // Video thumbnail area
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: _getMuscleGroupColor(exercise.muscleGroup).withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Stack(
              children: [
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                // Play button
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                // Muscle group badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatMuscleGroup(exercise.muscleGroup),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exercise info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.targetSets} sets x ${exercise.targetReps} reps',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (exercise.restSeconds != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Rest: ${exercise.restSeconds}s',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
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

  Widget _buildSetsTable(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    'SET',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'PREVIOUS',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'LBS',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'REPS',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const Divider(height: 1),

          // Set rows
          ...widget.exerciseLog.sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return _buildSetRow(theme, index, set);
          }),
        ],
      ),
    );
  }

  Widget _buildSetRow(ThemeData theme, int index, SetLogState set) {
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
                controller: _weightControllers[index],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                enabled: !set.isCompleted,
                decoration: InputDecoration(
                  hintText: set.lastWeight?.round().toString() ?? '0',
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: set.isCompleted
                      ? theme.dividerColor.withValues(alpha: 0.3)
                      : theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
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
                ),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Reps input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _repsControllers[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                enabled: !set.isCompleted,
                decoration: InputDecoration(
                  hintText: set.lastReps?.toString() ?? set.targetReps.toString(),
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: set.isCompleted
                      ? theme.dividerColor.withValues(alpha: 0.3)
                      : theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
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
                ),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Complete button
          SizedBox(
            width: 48,
            child: set.isCompleted
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : IconButton(
                    onPressed: () => _completeSet(index),
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

  void _completeSet(int index) {
    final weightText = _weightControllers[index].text;
    final repsText = _repsControllers[index].text;
    final set = widget.exerciseLog.sets[index];

    // Use input value, fall back to placeholder (last weight/reps)
    final weight = double.tryParse(weightText) ?? set.lastWeight ?? 0;
    final reps = int.tryParse(repsText) ?? set.lastReps ?? set.targetReps;

    // Update the text controllers with actual values if they were empty
    if (weightText.isEmpty) {
      _weightControllers[index].text = weight.round().toString();
    }
    if (repsText.isEmpty) {
      _repsControllers[index].text = reps.toString();
    }

    widget.onSetCompleted(index, weight, reps);
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

  String _formatMuscleGroup(String muscleGroup) {
    return muscleGroup
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
