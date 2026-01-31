import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../programs/data/models/program_week_model.dart';
import '../../data/models/trainee_model.dart';
import '../providers/trainer_provider.dart';

/// Full-page program options screen for managing a trainee's program.
class ProgramOptionsScreen extends ConsumerStatefulWidget {
  final int traineeId;
  final ProgramSummary program;

  const ProgramOptionsScreen({
    super.key,
    required this.traineeId,
    required this.program,
  });

  @override
  ConsumerState<ProgramOptionsScreen> createState() => _ProgramOptionsScreenState();
}

class _ProgramOptionsScreenState extends ConsumerState<ProgramOptionsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Options'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Program info card
          _buildProgramInfoCard(theme),
          const SizedBox(height: 32),

          // Options
          _buildOptionTile(
            theme: theme,
            icon: Icons.edit,
            title: 'Edit Program',
            subtitle: 'Modify exercises, sets, and reps',
            color: Colors.green,
            onTap: () => _navigateToEditProgram(context),
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            theme: theme,
            icon: Icons.swap_horiz,
            title: 'Change Program',
            subtitle: 'Assign a different program',
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              context.push('/trainer/programs/assign/${widget.traineeId}');
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            theme: theme,
            icon: Icons.cancel,
            title: 'End Program',
            subtitle: 'Remove this program from trainee',
            color: Colors.red,
            isDestructive: true,
            onTap: () => _navigateToEndProgram(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.program.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatStartDateLabel(widget.program.startDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? color.withValues(alpha: 0.3)
                : theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? color : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
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

  void _navigateToEditProgram(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditAssignedProgramScreen(
          traineeId: widget.traineeId,
          program: widget.program,
        ),
      ),
    );
  }

  void _navigateToEndProgram(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EndProgramScreen(
          traineeId: widget.traineeId,
          program: widget.program,
        ),
      ),
    );
  }
}

/// Screen to confirm ending a program.
class EndProgramScreen extends ConsumerStatefulWidget {
  final int traineeId;
  final ProgramSummary program;

  const EndProgramScreen({
    super.key,
    required this.traineeId,
    required this.program,
  });

  @override
  ConsumerState<EndProgramScreen> createState() => _EndProgramScreenState();
}

class _EndProgramScreenState extends ConsumerState<EndProgramScreen> {
  bool _isLoading = false;

  Future<void> _endProgram() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.delete(ApiConstants.programDetail(widget.program.id));

      if (mounted) {
        ref.invalidate(traineeDetailProvider(widget.traineeId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program ended successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to trainee detail
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name?.contains('trainee') == true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end program: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('End Program'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'End "${widget.program.name}"?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This will remove the program from this trainee. They will no longer have a workout schedule until you assign a new program.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _endProgram,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('End Program'),
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
}

/// Screen to edit an assigned program.
class EditAssignedProgramScreen extends ConsumerStatefulWidget {
  final int traineeId;
  final ProgramSummary program;

  const EditAssignedProgramScreen({
    super.key,
    required this.traineeId,
    required this.program,
  });

  @override
  ConsumerState<EditAssignedProgramScreen> createState() => _EditAssignedProgramScreenState();
}

class _EditAssignedProgramScreenState extends ConsumerState<EditAssignedProgramScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<ProgramWeek> _weeks = [];
  int _selectedWeekIndex = 0;
  Set<int> _loggedDayIndices = {}; // Global day indices that have been logged

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(
        ApiConstants.programDetail(widget.program.id),
      );

      final scheduleData = response.data['schedule'];

      // Handle different schedule formats
      List<dynamic>? weeksData;
      if (scheduleData is Map<String, dynamic>) {
        weeksData = scheduleData['weeks'] as List<dynamic>?;
      } else if (scheduleData is List) {
        // Schedule might be stored as a list directly
        weeksData = scheduleData;
      }

      if (weeksData != null && weeksData.isNotEmpty) {
        _weeks = weeksData.map((w) => ProgramWeek.fromJson(w as Map<String, dynamic>)).toList();
      }

      // Calculate logged days based on start date
      _calculateLoggedDays();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load program: ${e.toString()}';
      });
    }
  }

  void _calculateLoggedDays() {
    // Mark all days before today as logged (based on start date)
    if (widget.program.startDate == null) return;

    try {
      final startDate = DateTime.parse(widget.program.startDate!);
      final now = DateTime.now();
      final daysSinceStart = now.difference(startDate).inDays;

      for (int i = 0; i < daysSinceStart && i >= 0; i++) {
        _loggedDayIndices.add(i);
      }
    } catch (_) {}
  }

  bool _isDayEditable(int weekIndex, int dayIndex) {
    final globalDayIndex = (weekIndex * 7) + dayIndex;
    return !_loggedDayIndices.contains(globalDayIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Program')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Program')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() { _isLoading = true; _error = null; });
                  _loadProgram();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_weeks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Program')),
        body: const Center(child: Text('No program schedule found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(onPressed: _saveChanges, child: const Text('Save')),
        ],
      ),
      body: Column(
        children: [
          _buildWeekSelector(theme),
          Expanded(child: _buildWeekContent(theme, _weeks[_selectedWeekIndex])),
        ],
      ),
    );
  }

  Widget _buildWeekSelector(ThemeData theme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _weeks.length,
        itemBuilder: (context, index) {
          final week = _weeks[index];
          final isSelected = index == _selectedWeekIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedWeekIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text('W${week.weekNumber}', style: TextStyle(color: isSelected ? Colors.white : null, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekContent(ThemeData theme, ProgramWeek week) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('W${week.weekNumber}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Week ${week.weekNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('${week.totalWorkoutDays} workout days • ${week.totalExercises} exercises', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...week.days.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final day = entry.value;
          final isEditable = _isDayEditable(_selectedWeekIndex, dayIndex);
          return _buildDayCard(theme, dayIndex, day, isEditable);
        }),
      ],
    );
  }

  Widget _buildDayCard(ThemeData theme, int dayIndex, WorkoutDay day, bool isEditable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: !isEditable ? Colors.grey.withValues(alpha: 0.3) : theme.dividerColor),
      ),
      color: !isEditable ? Colors.grey.withValues(alpha: 0.05) : null,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: !isEditable ? Colors.grey.withValues(alpha: 0.2) : day.isRestDay ? Colors.grey.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              !isEditable ? Icons.lock : day.isRestDay ? Icons.bed : Icons.fitness_center,
              color: !isEditable ? Colors.grey : day.isRestDay ? Colors.grey : theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text('Day ${dayIndex + 1}', style: TextStyle(fontWeight: FontWeight.w600, color: !isEditable ? Colors.grey : null)),
              if (!isEditable) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Logged', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              ],
            ],
          ),
          subtitle: Text(
            day.isRestDay ? 'Rest Day' : '${day.name} • ${day.exercises.length} exercises',
            style: TextStyle(color: !isEditable ? Colors.grey : Colors.grey[600], fontSize: 12),
          ),
          children: day.isRestDay
              ? [Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(Icons.self_improvement, color: Colors.grey[400]), const SizedBox(width: 12), Text('Recovery & rest', style: TextStyle(color: Colors.grey[600]))]))]
              : [
                  ...day.exercises.map((e) => _buildExerciseRow(theme, e, dayIndex, isEditable)),
                  if (isEditable)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddExerciseDialog(dayIndex),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Exercise'),
                      ),
                    ),
                ],
        ),
      ),
    );
  }

  Widget _buildExerciseRow(ThemeData theme, WorkoutExercise exercise, int dayIndex, bool isEditable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)))),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.exerciseName, style: TextStyle(fontWeight: FontWeight.w500, color: !isEditable ? Colors.grey : null)),
                Text(exercise.muscleGroup, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          if (isEditable)
            GestureDetector(
              onTap: () => _showEditExerciseDialog(exercise, dayIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Text('${exercise.sets} × ${exercise.reps}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 14, color: theme.colorScheme.primary),
                ]),
              ),
            )
          else
            Text('${exercise.sets} × ${exercise.reps}', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _exerciseLibrary = [
    {'id': 1, 'name': 'Barbell Bench Press', 'muscle': 'chest'},
    {'id': 2, 'name': 'Incline Dumbbell Press', 'muscle': 'chest'},
    {'id': 30, 'name': 'Barbell Deadlift', 'muscle': 'back'},
    {'id': 31, 'name': 'Barbell Bent-Over Row', 'muscle': 'back'},
    {'id': 32, 'name': 'Lat Pulldown', 'muscle': 'back'},
    {'id': 15, 'name': 'Overhead Press', 'muscle': 'shoulders'},
    {'id': 16, 'name': 'Lateral Raises', 'muscle': 'shoulders'},
    {'id': 50, 'name': 'Barbell Back Squat', 'muscle': 'legs'},
    {'id': 51, 'name': 'Romanian Deadlift', 'muscle': 'legs'},
    {'id': 52, 'name': 'Leg Press', 'muscle': 'legs'},
    {'id': 25, 'name': 'Tricep Pushdown', 'muscle': 'arms'},
    {'id': 45, 'name': 'Barbell Bicep Curl', 'muscle': 'arms'},
  ];

  void _showEditExerciseDialog(WorkoutExercise exercise, int dayIndex) {
    int sets = exercise.sets;
    int reps = exercise.reps;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(exercise.exerciseName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () { Navigator.pop(context); _showReplaceExerciseDialog(exercise, dayIndex); }, icon: const Icon(Icons.swap_horiz), style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1), foregroundColor: Colors.blue)),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () { Navigator.pop(context); _removeExercise(exercise, dayIndex); }, icon: const Icon(Icons.delete_outline), style: IconButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.1), foregroundColor: Colors.red)),
                ],
              ),
              const SizedBox(height: 24),
              Row(children: [const SizedBox(width: 60, child: Text('Sets:')), Expanded(child: Slider(value: sets.toDouble(), min: 1, max: 8, divisions: 7, onChanged: (v) => setModalState(() => sets = v.round()))), SizedBox(width: 40, child: Text('$sets', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center))]),
              Row(children: [const SizedBox(width: 60, child: Text('Reps:')), Expanded(child: Slider(value: reps.toDouble(), min: 1, max: 30, divisions: 29, onChanged: (v) => setModalState(() => reps = v.round()))), SizedBox(width: 40, child: Text('$reps', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center))]),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { _updateExercise(exercise, dayIndex, sets, reps); Navigator.pop(context); }, child: const Text('Save Changes'))),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExerciseDialog(int dayIndex) => _showExercisePicker(title: 'Add Exercise', onSelect: (e) => _addExercise(e, dayIndex));
  void _showReplaceExerciseDialog(WorkoutExercise old, int dayIndex) => _showExercisePicker(title: 'Replace Exercise', onSelect: (e) => _replaceExercise(old, e, dayIndex));

  void _showExercisePicker({required String title, required void Function(Map<String, dynamic>) onSelect}) {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _exerciseLibrary.where((e) => search.isEmpty || e['name'].toString().toLowerCase().contains(search.toLowerCase())).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v) => setModalState(() => search = v)),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final e = filtered[i];
                      return ListTile(title: Text(e['name'] as String), subtitle: Text(e['muscle'] as String), trailing: const Icon(Icons.add), onTap: () { Navigator.pop(context); onSelect(e); });
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

  void _updateExercise(WorkoutExercise exercise, int dayIndex, int sets, int reps) {
    setState(() {
      final week = _weeks[_selectedWeekIndex];
      final day = week.days[dayIndex];
      final updated = day.exercises.map((e) => e.exerciseId == exercise.exerciseId ? e.copyWith(sets: sets, reps: reps) : e).toList();
      final days = List<WorkoutDay>.from(week.days);
      days[dayIndex] = day.copyWith(exercises: updated);
      _weeks[_selectedWeekIndex] = week.copyWith(days: days);
    });
  }

  void _addExercise(Map<String, dynamic> data, int dayIndex) {
    setState(() {
      final week = _weeks[_selectedWeekIndex];
      final day = week.days[dayIndex];
      final newEx = WorkoutExercise(exerciseId: data['id'] as int, exerciseName: data['name'] as String, muscleGroup: data['muscle'] as String, sets: 3, reps: 10);
      final days = List<WorkoutDay>.from(week.days);
      days[dayIndex] = day.copyWith(exercises: [...day.exercises, newEx]);
      _weeks[_selectedWeekIndex] = week.copyWith(days: days);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${data['name']}')));
  }

  void _replaceExercise(WorkoutExercise old, Map<String, dynamic> data, int dayIndex) {
    setState(() {
      final week = _weeks[_selectedWeekIndex];
      final day = week.days[dayIndex];
      final updated = day.exercises.map((e) => e.exerciseId == old.exerciseId ? WorkoutExercise(exerciseId: data['id'] as int, exerciseName: data['name'] as String, muscleGroup: data['muscle'] as String, sets: e.sets, reps: e.reps) : e).toList();
      final days = List<WorkoutDay>.from(week.days);
      days[dayIndex] = day.copyWith(exercises: updated);
      _weeks[_selectedWeekIndex] = week.copyWith(days: days);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Replaced with ${data['name']}')));
  }

  void _removeExercise(WorkoutExercise exercise, int dayIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: Text('Remove "${exercise.exerciseName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final week = _weeks[_selectedWeekIndex];
                final day = week.days[dayIndex];
                final days = List<WorkoutDay>.from(week.days);
                days[dayIndex] = day.copyWith(exercises: day.exercises.where((e) => e.exerciseId != exercise.exerciseId).toList());
                _weeks[_selectedWeekIndex] = week.copyWith(days: days);
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed ${exercise.exerciseName}')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.patch(ApiConstants.programDetail(widget.program.id), data: {'schedule': {'weeks': _weeks.map((w) => w.toJson()).toList()}});
      if (mounted) {
        ref.invalidate(traineeDetailProvider(widget.traineeId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program updated successfully'), backgroundColor: Colors.green));
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
