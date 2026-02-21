import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/program_week_model.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../widgets/exercise_picker_sheet.dart';

class WeekEditorScreen extends ConsumerStatefulWidget {
  final ProgramWeek week;
  final Function(ProgramWeek) onSave;
  /// Callback to apply superset to all weeks. Parameters: dayIndex, exerciseNames, groupId
  final Function(int dayIndex, List<String> exerciseNames, String groupId)? onApplySupersetToAllWeeks;
  /// Callback to apply rest day change to all weeks. Parameters: dayIndex, isRestDay
  final Function(int dayIndex, bool isRestDay)? onApplyRestDayToAllWeeks;
  /// Callback to delete this week
  final VoidCallback? onDeleteWeek;
  /// Whether this week can be deleted (e.g., must have at least 1 week)
  final bool canDelete;

  const WeekEditorScreen({
    super.key,
    required this.week,
    required this.onSave,
    this.onApplySupersetToAllWeeks,
    this.onApplyRestDayToAllWeeks,
    this.onDeleteWeek,
    this.canDelete = true,
  });

  @override
  ConsumerState<WeekEditorScreen> createState() => _WeekEditorScreenState();
}

class _WeekEditorScreenState extends ConsumerState<WeekEditorScreen> {
  late ProgramWeek _week;
  int _selectedDayIndex = 0;
  bool _isSelectionMode = false;
  final Set<int> _selectedExerciseIndices = {};

  @override
  void initState() {
    super.initState();
    _week = widget.week;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedExerciseIndices.clear();
    });
  }

  void _toggleExerciseSelection(int index) {
    setState(() {
      if (_selectedExerciseIndices.contains(index)) {
        _selectedExerciseIndices.remove(index);
      } else {
        _selectedExerciseIndices.add(index);
      }
    });
  }

  void _createSuperset() {
    if (_selectedExerciseIndices.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 exercises to create a superset')),
      );
      return;
    }

    // Show dialog to choose scope
    _showSupersetScopeDialog();
  }

  void _showSupersetScopeDialog() {
    final theme = Theme.of(context);
    final day = _week.days[_selectedDayIndex];
    final selectedExerciseNames = _selectedExerciseIndices
        .map((i) => day.exercises[i].exerciseName)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(dialogContext).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(Icons.link, size: 48, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'Create Superset',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Group ${selectedExerciseNames.length} exercises together',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _applySupersetToThisWeek();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('This Week'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onApplySupersetToAllWeeks != null
                        ? () {
                            Navigator.pop(dialogContext);
                            _applySupersetToAllWeeks();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('All Weeks'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applySupersetToThisWeek() {
    setState(() {
      final groupId = DateTime.now().millisecondsSinceEpoch.toString();
      final day = _week.days[_selectedDayIndex];
      final updatedExercises = List<WorkoutExercise>.from(day.exercises);

      for (final index in _selectedExerciseIndices) {
        updatedExercises[index] = updatedExercises[index].copyWith(supersetGroupId: groupId);
      }

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(exercises: updatedExercises);
      _week = _week.copyWith(days: updatedDays);

      _isSelectionMode = false;
      _selectedExerciseIndices.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Superset created for this week!'), backgroundColor: Colors.green),
    );
  }

  void _applySupersetToAllWeeks() {
    final groupId = DateTime.now().millisecondsSinceEpoch.toString();
    final day = _week.days[_selectedDayIndex];

    // Get exercise names for the selected exercises
    final exerciseNames = _selectedExerciseIndices
        .map((i) => day.exercises[i].exerciseName)
        .toList();

    // Apply to this week first
    setState(() {
      final updatedExercises = List<WorkoutExercise>.from(day.exercises);

      for (final index in _selectedExerciseIndices) {
        updatedExercises[index] = updatedExercises[index].copyWith(supersetGroupId: groupId);
      }

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(exercises: updatedExercises);
      _week = _week.copyWith(days: updatedDays);

      _isSelectionMode = false;
      _selectedExerciseIndices.clear();
    });

    // Call parent to apply to all other weeks
    widget.onApplySupersetToAllWeeks?.call(_selectedDayIndex, exerciseNames, groupId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Superset created for all weeks!'), backgroundColor: Colors.green),
    );
  }

  void _removeFromSuperset(int index) {
    setState(() {
      final day = _week.days[_selectedDayIndex];
      final updatedExercises = List<WorkoutExercise>.from(day.exercises);
      updatedExercises[index] = updatedExercises[index].copyWith(clearSupersetGroup: true);

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(exercises: updatedExercises);
      _week = _week.copyWith(days: updatedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDay = _week.days[_selectedDayIndex];
    final hasExercises = currentDay.exercises.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedExerciseIndices.length} selected' : 'Week ${_week.weekNumber}'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (!_isSelectionMode && hasExercises && !currentDay.isRestDay)
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Create Superset',
              onPressed: _toggleSelectionMode,
            ),
          if (!_isSelectionMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteWeekDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  enabled: widget.canDelete,
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: widget.canDelete ? Colors.red : Colors.grey,
                    ),
                    title: Text(
                      'Delete Week',
                      style: TextStyle(
                        color: widget.canDelete ? Colors.red : Colors.grey,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          if (!_isSelectionMode)
            IconButton(
              onPressed: () {
                widget.onSave(_week);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              tooltip: 'Save',
            ),
        ],
      ),
      body: Column(
        children: [
          // Day selector
          _buildDaySelector(context),

          // Selection mode banner
          if (_isSelectionMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: theme.colorScheme.primaryContainer,
              child: Text(
                'Select exercises to group as a superset',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),

          // Day content
          Expanded(
            child: _buildDayContent(context, currentDay),
          ),
        ],
      ),
      floatingActionButton: currentDay.isRestDay
          ? null
          : _isSelectionMode
              ? FloatingActionButton.extended(
                  onPressed: _selectedExerciseIndices.length >= 2 ? _createSuperset : null,
                  backgroundColor: _selectedExerciseIndices.length >= 2
                      ? theme.colorScheme.primary
                      : Colors.grey,
                  icon: const Icon(Icons.link),
                  label: const Text('Create Superset'),
                )
              : FloatingActionButton.extended(
                  onPressed: () => _showAddExerciseSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    final theme = Theme.of(context);
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = _week.days[index];
          final isSelected = index == _selectedDayIndex;

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : day.isRestDay
                        ? Colors.grey.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    day.isRestDay ? Icons.bed : Icons.fitness_center,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : day.isRestDay
                            ? Colors.grey
                            : theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayContent(BuildContext context, WorkoutDay day) {
    if (day.isRestDay) {
      return _buildRestDayContent(context, day);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: day.exercises.length + 1, // +1 for header
      onReorder: (oldIndex, newIndex) {
        if (oldIndex == 0 || newIndex == 0) return; // Don't reorder header
        final actualOld = oldIndex - 1;
        var actualNew = newIndex - 1;
        if (actualNew > actualOld) actualNew--;
        _reorderExercise(actualOld, actualNew);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            key: const ValueKey('header'),
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildDayHeader(context, day),
          );
        }

        final exercise = day.exercises[index - 1];
        return _buildExerciseCard(context, exercise, index - 1);
      },
    );
  }

  Widget _buildRestDayContent(BuildContext context, WorkoutDay day) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.self_improvement, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Rest Day',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Recovery is essential for growth',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _convertToWorkoutDay(),
            icon: const Icon(Icons.fitness_center),
            label: const Text('Convert to Workout Day'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(BuildContext context, WorkoutDay day) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.exercises.length} exercises • ${day.exercises.fold(0, (sum, e) => sum + e.sets)} sets',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Rename Day'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rest',
                child: Row(
                  children: [
                    Icon(Icons.bed, size: 18),
                    SizedBox(width: 8),
                    Text('Convert to Rest Day'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Exercises', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _showRenameDayDialog();
                  break;
                case 'rest':
                  _convertToRestDay();
                  break;
                case 'clear':
                  _clearExercises();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, WorkoutExercise exercise, int index) {
    final theme = Theme.of(context);
    final isSelected = _selectedExerciseIndices.contains(index);
    final isInSuperset = exercise.isInSuperset;

    // Check if this is part of a superset group and its position
    final day = _week.days[_selectedDayIndex];
    final supersetInfo = _getSupersetInfo(day.exercises, index);

    return Card(
      key: ValueKey(exercise.exerciseId.toString() + index.toString()),
      margin: EdgeInsets.only(
        bottom: supersetInfo.isLastInGroup ? 8 : 0,
        left: isInSuperset ? 8 : 0,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(supersetInfo.isMiddle ? 0 : 12),
        side: BorderSide(
          color: isInSuperset ? theme.colorScheme.secondary : theme.dividerColor,
          width: isInSuperset ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _isSelectionMode ? () => _toggleExerciseSelection(index) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Selection checkbox or drag handle
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleExerciseSelection(index),
                )
              else
                Icon(Icons.drag_handle, color: Colors.grey[400]),
              const SizedBox(width: 8),

              // Superset indicator
              if (isInSuperset && !_isSelectionMode) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, size: 12, color: theme.colorScheme.secondary),
                      const SizedBox(width: 2),
                      Text(
                        'SS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMiniChip(context, exercise.muscleGroup),
                        const SizedBox(width: 8),
                        Text(
                          '${exercise.sets} × ${exercise.reps}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (exercise.restSeconds != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatRestTime(exercise.restSeconds!),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              if (!_isSelectionMode) ...[
                // Superset menu (if in superset)
                if (isInSuperset)
                  IconButton(
                    icon: const Icon(Icons.link_off, size: 20),
                    tooltip: 'Remove from superset',
                    onPressed: () => _removeFromSuperset(index),
                  ),

                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditExerciseDialog(context, exercise, index),
                ),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () => _removeExercise(index),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _SupersetInfo _getSupersetInfo(List<WorkoutExercise> exercises, int index) {
    final exercise = exercises[index];
    if (!exercise.isInSuperset) {
      return _SupersetInfo(isFirst: false, isLast: false, isMiddle: false, isLastInGroup: true);
    }

    final groupId = exercise.supersetGroupId;
    final prevInGroup = index > 0 && exercises[index - 1].supersetGroupId == groupId;
    final nextInGroup = index < exercises.length - 1 && exercises[index + 1].supersetGroupId == groupId;

    return _SupersetInfo(
      isFirst: !prevInGroup && nextInGroup,
      isLast: prevInGroup && !nextInGroup,
      isMiddle: prevInGroup && nextInGroup,
      isLastInGroup: !nextInGroup,
    );
  }

  Widget _buildMiniChip(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.replaceAll('_', ' ').split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
        style: TextStyle(color: Colors.grey[600], fontSize: 11),
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ExercisePickerSheet(
          scrollController: scrollController,
          onExerciseSelected: (exercise) {
            _addExercise(exercise);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _addExercise(ExerciseModel exercise) {
    setState(() {
      final day = _week.days[_selectedDayIndex];
      final newExercise = WorkoutExercise(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        muscleGroup: exercise.muscleGroup,
        sets: 3,
        reps: '10',
      );

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(
        exercises: [...day.exercises, newExercise],
      );

      _week = _week.copyWith(days: updatedDays);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      final day = _week.days[_selectedDayIndex];
      final updatedExercises = List<WorkoutExercise>.from(day.exercises);
      updatedExercises.removeAt(index);

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(exercises: updatedExercises);

      _week = _week.copyWith(days: updatedDays);
    });
  }

  void _reorderExercise(int oldIndex, int newIndex) {
    setState(() {
      final day = _week.days[_selectedDayIndex];
      final updatedExercises = List<WorkoutExercise>.from(day.exercises);
      final item = updatedExercises.removeAt(oldIndex);
      updatedExercises.insert(newIndex, item);

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(exercises: updatedExercises);

      _week = _week.copyWith(days: updatedDays);
    });
  }

  /// Parse a reps string (e.g. "8-10" or "12") to an int for the editor.
  /// For range strings, uses the high end of the range.
  int _parseRepsToInt(String reps) {
    if (reps.contains('-')) {
      final parts = reps.split('-');
      return int.tryParse(parts.last.trim()) ?? 10;
    }
    return int.tryParse(reps) ?? 10;
  }

  void _showEditExerciseDialog(BuildContext context, WorkoutExercise exercise, int index) {
    final theme = Theme.of(context);
    int sets = exercise.sets;
    int reps = _parseRepsToInt(exercise.reps);
    int restSeconds = exercise.restSeconds ?? 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: (bottomPadding > 0 ? bottomPadding : 24) + keyboardHeight,
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
                  Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sets
                  Row(
                    children: [
                      const SizedBox(width: 60, child: Text('Sets:')),
                      IconButton(
                        onPressed: () {
                          if (sets > 1) setModalState(() => sets--);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        sets.toString(),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          if (sets < 10) setModalState(() => sets++);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),

                  // Reps
                  Row(
                    children: [
                      const SizedBox(width: 60, child: Text('Reps:')),
                      IconButton(
                        onPressed: () {
                          if (reps > 1) setModalState(() => reps--);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        reps.toString(),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          if (reps < 50) setModalState(() => reps++);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),

                  // Rest Time
                  Row(
                    children: [
                      const SizedBox(width: 60, child: Text('Rest:')),
                      IconButton(
                        onPressed: () {
                          if (restSeconds > 15) setModalState(() => restSeconds -= 15);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        _formatRestTime(restSeconds),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          if (restSeconds < 300) setModalState(() => restSeconds += 15);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rest time presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('30s', () => setModalState(() => restSeconds = 30)),
                      _buildPresetChip('60s', () => setModalState(() => restSeconds = 60)),
                      _buildPresetChip('90s', () => setModalState(() => restSeconds = 90)),
                      _buildPresetChip('2min', () => setModalState(() => restSeconds = 120)),
                      _buildPresetChip('3min', () => setModalState(() => restSeconds = 180)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick presets
                  const Text('Quick Presets:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('3×8', () => setModalState(() { sets = 3; reps = 8; })),
                      _buildPresetChip('3×10', () => setModalState(() { sets = 3; reps = 10; })),
                      _buildPresetChip('3×12', () => setModalState(() { sets = 3; reps = 12; })),
                      _buildPresetChip('4×8', () => setModalState(() { sets = 4; reps = 8; })),
                      _buildPresetChip('4×10', () => setModalState(() { sets = 4; reps = 10; })),
                      _buildPresetChip('5×5', () => setModalState(() { sets = 5; reps = 5; })),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateExercise(index, sets, reps, restSeconds);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Update'),
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

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }

  void _updateExercise(int index, int sets, int reps, int restSeconds) {
    final repsStr = reps.toString();
    setState(() {
      final day = _week.days[_selectedDayIndex];
      final updatedExercises = List<WorkoutExercise>.from(day.exercises);
      updatedExercises[index] = updatedExercises[index].copyWith(
        sets: sets,
        reps: repsStr,
        restSeconds: restSeconds,
      );

      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = day.copyWith(exercises: updatedExercises);

      _week = _week.copyWith(days: updatedDays);
    });
  }

  String _formatRestTime(int seconds) {
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      if (secs == 0) {
        return '${mins}m';
      }
      return '${mins}m ${secs}s';
    }
    return '${seconds}s';
  }

  void _showRenameDayDialog() {
    final controller = TextEditingController(text: _week.days[_selectedDayIndex].name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Day'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Day Name',
            hintText: 'e.g., Push, Pull, Upper',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final updatedDays = List<WorkoutDay>.from(_week.days);
                updatedDays[_selectedDayIndex] = updatedDays[_selectedDayIndex].copyWith(
                  name: controller.text,
                );
                _week = _week.copyWith(days: updatedDays);
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _convertToRestDay() {
    final theme = Theme.of(context);
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[_selectedDayIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(dialogContext).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(Icons.bed, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Convert to Rest Day',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Make $dayName a rest day',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _applyRestDayToThisWeek();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('This Week Only'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onApplyRestDayToAllWeeks != null
                        ? () {
                            Navigator.pop(dialogContext);
                            _applyRestDayToAllWeeks();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('All Weeks'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyRestDayToThisWeek() {
    setState(() {
      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = WorkoutDay(
        name: 'Rest',
        isRestDay: true,
        exercises: [],
      );
      _week = _week.copyWith(days: updatedDays);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Converted to rest day for this week'), backgroundColor: Colors.green),
    );
  }

  void _showDeleteWeekDialog() {
    if (!widget.canDelete) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Week?'),
        content: Text(
          'Are you sure you want to delete Week ${_week.weekNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close week editor
              widget.onDeleteWeek?.call();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _applyRestDayToAllWeeks() {
    // Apply to this week first
    setState(() {
      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = WorkoutDay(
        name: 'Rest',
        isRestDay: true,
        exercises: [],
      );
      _week = _week.copyWith(days: updatedDays);
    });

    // Call parent to apply to all other weeks
    widget.onApplyRestDayToAllWeeks?.call(_selectedDayIndex, true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Converted to rest day for all weeks'), backgroundColor: Colors.green),
    );
  }

  void _convertToWorkoutDay() {
    final theme = Theme.of(context);
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[_selectedDayIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(dialogContext).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(Icons.fitness_center, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Convert to Workout Day',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Make $dayName a workout day',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _applyWorkoutDayToThisWeek();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('This Week Only'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onApplyRestDayToAllWeeks != null
                        ? () {
                            Navigator.pop(dialogContext);
                            _applyWorkoutDayToAllWeeks();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('All Weeks'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyWorkoutDayToThisWeek() {
    setState(() {
      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = WorkoutDay(
        name: 'Workout',
        isRestDay: false,
        exercises: [],
      );
      _week = _week.copyWith(days: updatedDays);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Converted to workout day for this week'), backgroundColor: Colors.green),
    );
  }

  void _applyWorkoutDayToAllWeeks() {
    // Apply to this week first
    setState(() {
      final updatedDays = List<WorkoutDay>.from(_week.days);
      updatedDays[_selectedDayIndex] = WorkoutDay(
        name: 'Workout',
        isRestDay: false,
        exercises: [],
      );
      _week = _week.copyWith(days: updatedDays);
    });

    // Call parent to apply to all other weeks (false means convert TO workout day)
    widget.onApplyRestDayToAllWeeks?.call(_selectedDayIndex, false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Converted to workout day for all weeks'), backgroundColor: Colors.green),
    );
  }

  void _clearExercises() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Exercises'),
        content: const Text('Are you sure you want to remove all exercises from this day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                final updatedDays = List<WorkoutDay>.from(_week.days);
                updatedDays[_selectedDayIndex] = updatedDays[_selectedDayIndex].copyWith(
                  exercises: [],
                );
                _week = _week.copyWith(days: updatedDays);
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}


class _SupersetInfo {
  final bool isFirst;
  final bool isLast;
  final bool isMiddle;
  final bool isLastInGroup;

  _SupersetInfo({
    required this.isFirst,
    required this.isLast,
    required this.isMiddle,
    required this.isLastInGroup,
  });
}
