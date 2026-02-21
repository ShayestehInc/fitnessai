import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../programs/data/models/program_week_model.dart';

/// A calendar item representing a single day in the program
class CalendarDayItem {
  final DateTime date;
  final int programDayNumber; // Overall day number (1, 2, 3...)
  final int weekNumber;
  final int dayInWeek; // 0-6
  final WorkoutDay? workout;
  final bool isToday;
  final bool isPast;
  final bool isMissed;

  CalendarDayItem({
    required this.date,
    required this.programDayNumber,
    required this.weekNumber,
    required this.dayInWeek,
    this.workout,
    required this.isToday,
    required this.isPast,
    this.isMissed = false,
  });
}

class WorkoutCalendarScreen extends ConsumerStatefulWidget {
  /// Optional: When provided, shows calendar for this trainee (trainer mode)
  final int? traineeId;
  final String? traineeName;
  final int? programId;

  const WorkoutCalendarScreen({
    super.key,
    this.traineeId,
    this.traineeName,
    this.programId,
  });

  @override
  ConsumerState<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends ConsumerState<WorkoutCalendarScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _programName;
  DateTime? _startDate;
  int? _programId;
  List<ProgramWeek> _weeks = [];
  List<CalendarDayItem> _calendarDays = [];
  List<String> _missedDates = []; // Dates marked as missed (YYYY-MM-DD format)
  final ScrollController _scrollController = ScrollController();
  bool _hasChanges = false;

  bool get _isTrainerMode => widget.traineeId != null;

  // Exercise library for replacements
  final List<Map<String, dynamic>> _exerciseLibrary = [
    {'id': 1, 'name': 'Barbell Bench Press', 'muscle': 'chest'},
    {'id': 2, 'name': 'Incline Dumbbell Press', 'muscle': 'chest'},
    {'id': 3, 'name': 'Cable Flyes', 'muscle': 'chest'},
    {'id': 4, 'name': 'Push-ups', 'muscle': 'chest'},
    {'id': 5, 'name': 'Dumbbell Bench Press', 'muscle': 'chest'},
    {'id': 10, 'name': 'Pull-ups', 'muscle': 'back'},
    {'id': 11, 'name': 'Barbell Bent-Over Row', 'muscle': 'back'},
    {'id': 12, 'name': 'Lat Pulldown', 'muscle': 'back'},
    {'id': 13, 'name': 'Seated Cable Row', 'muscle': 'back'},
    {'id': 14, 'name': 'Dumbbell Row', 'muscle': 'back'},
    {'id': 15, 'name': 'T-Bar Row', 'muscle': 'back'},
    {'id': 20, 'name': 'Overhead Press', 'muscle': 'shoulders'},
    {'id': 21, 'name': 'Lateral Raises', 'muscle': 'shoulders'},
    {'id': 22, 'name': 'Front Raises', 'muscle': 'shoulders'},
    {'id': 23, 'name': 'Face Pulls', 'muscle': 'shoulders'},
    {'id': 24, 'name': 'Arnold Press', 'muscle': 'shoulders'},
    {'id': 25, 'name': 'Tricep Pushdown', 'muscle': 'arms'},
    {'id': 26, 'name': 'Tricep Dips', 'muscle': 'arms'},
    {'id': 27, 'name': 'Skull Crushers', 'muscle': 'arms'},
    {'id': 28, 'name': 'Overhead Tricep Extension', 'muscle': 'arms'},
    {'id': 40, 'name': 'Dumbbell Bicep Curl', 'muscle': 'arms'},
    {'id': 41, 'name': 'Hammer Curls', 'muscle': 'arms'},
    {'id': 42, 'name': 'Preacher Curls', 'muscle': 'arms'},
    {'id': 43, 'name': 'Concentration Curls', 'muscle': 'arms'},
    {'id': 44, 'name': 'Cable Curls', 'muscle': 'arms'},
    {'id': 45, 'name': 'Barbell Bicep Curl', 'muscle': 'arms'},
    {'id': 50, 'name': 'Barbell Back Squat', 'muscle': 'legs'},
    {'id': 51, 'name': 'Romanian Deadlift', 'muscle': 'legs'},
    {'id': 52, 'name': 'Leg Press', 'muscle': 'legs'},
    {'id': 53, 'name': 'Leg Curl', 'muscle': 'legs'},
    {'id': 54, 'name': 'Leg Extension', 'muscle': 'legs'},
    {'id': 55, 'name': 'Calf Raises', 'muscle': 'legs'},
    {'id': 56, 'name': 'Lunges', 'muscle': 'legs'},
    {'id': 57, 'name': 'Bulgarian Split Squat', 'muscle': 'legs'},
    {'id': 60, 'name': 'Plank', 'muscle': 'core'},
    {'id': 61, 'name': 'Crunches', 'muscle': 'core'},
    {'id': 62, 'name': 'Russian Twists', 'muscle': 'core'},
    {'id': 63, 'name': 'Hanging Leg Raises', 'muscle': 'core'},
    {'id': 64, 'name': 'Ab Wheel Rollout', 'muscle': 'core'},
    {'id': 70, 'name': 'Deadlift', 'muscle': 'back'},
    {'id': 71, 'name': 'Hip Thrust', 'muscle': 'glutes'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgram() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      int? programId = widget.programId;

      if (programId == null) {
        // Need to find the active program
        if (_isTrainerMode) {
          // Trainer viewing trainee's program - get trainee details
          final endpoint = '${ApiConstants.trainerTrainees}${widget.traineeId}/';
          final traineeResponse = await apiClient.dio.get(endpoint);
          final currentProgram = traineeResponse.data['current_program'];
          if (currentProgram == null) {
            setState(() {
              _isLoading = false;
              _error = 'No active program found for this trainee';
            });
            return;
          }
          programId = currentProgram['id'];
          _programName = currentProgram['name'];
          final startDateStr = currentProgram['start_date'];
          if (startDateStr != null) {
            _startDate = DateTime.parse(startDateStr);
          }
        } else {
          // Trainee viewing own program
          final programsResponse = await apiClient.dio.get(ApiConstants.programs);
          final programsList = programsResponse.data as List;

          if (programsList.isEmpty) {
            setState(() {
              _isLoading = false;
              _error = 'No active program found';
            });
            return;
          }

          final activeProgram = programsList.firstWhere(
            (p) => p['is_active'] == true,
            orElse: () => programsList.first,
          );

          programId = activeProgram['id'];
          _programName = activeProgram['name'];
          final startDateStr = activeProgram['start_date'];
          if (startDateStr != null) {
            _startDate = DateTime.parse(startDateStr);
          }
        }
      }

      _programId = programId;

      // Get full program details with schedule
      final detailResponse = await apiClient.dio.get(ApiConstants.programDetail(programId!));

      // Set program name and start date if not already set
      _programName ??= detailResponse.data['name'];
      if (_startDate == null) {
        final startDateStr = detailResponse.data['start_date'];
        if (startDateStr != null) {
          _startDate = DateTime.parse(startDateStr);
        }
      }

      final scheduleData = detailResponse.data['schedule'];
      List<dynamic>? weeksData;

      if (scheduleData is Map<String, dynamic>) {
        weeksData = scheduleData['weeks'] as List<dynamic>?;
      } else if (scheduleData is List) {
        weeksData = scheduleData;
      }

      if (weeksData != null && weeksData.isNotEmpty) {
        _weeks = weeksData.map((w) => ProgramWeek.fromJson(w as Map<String, dynamic>)).toList();
      }

      // Load missed dates
      final missedDatesData = detailResponse.data['missed_dates'];
      if (missedDatesData is List) {
        _missedDates = missedDatesData.map((d) => d.toString()).toList();
      }

      _buildCalendarDays();
      setState(() => _isLoading = false);

      // Scroll to today after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToToday();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load program: ${e.toString()}';
      });
    }
  }

  void _buildCalendarDays() {
    if (_startDate == null || _weeks.isEmpty) return;

    _calendarDays = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int programDayNumber = 1;

    for (int weekIndex = 0; weekIndex < _weeks.length; weekIndex++) {
      final week = _weeks[weekIndex];
      for (int dayIndex = 0; dayIndex < week.days.length; dayIndex++) {
        final day = week.days[dayIndex];
        final date = _startDate!.add(Duration(days: programDayNumber - 1));
        final dateOnly = DateTime(date.year, date.month, date.day);
        final dateStr = '${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}';

        _calendarDays.add(CalendarDayItem(
          date: date,
          programDayNumber: programDayNumber,
          weekNumber: week.weekNumber,
          dayInWeek: dayIndex,
          workout: day,
          isToday: dateOnly == today,
          isPast: dateOnly.isBefore(today),
          isMissed: _missedDates.contains(dateStr),
        ));

        programDayNumber++;
      }
    }
  }

  void _scrollToToday() {
    final todayIndex = _calendarDays.indexWhere((d) => d.isToday);
    if (todayIndex >= 0 && _scrollController.hasClients) {
      // Each card is approximately 100 height + 12 margin
      final offset = (todayIndex * 112.0) - 100;
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _programId == null) return;

    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.patch(
        ApiConstants.programDetail(_programId!),
        data: {'schedule': {'weeks': _weeks.map((w) => w.toJson()).toList()}},
      );
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isTrainerMode
            ? "${widget.traineeName ?? 'Trainee'}'s Schedule"
            : 'Workout Schedule'),
        actions: [
          if (_hasChanges && _isTrainerMode)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Save changes',
                    onPressed: _saveChanges,
                  ),
          if (!_isLoading && _calendarDays.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'Go to today',
              onPressed: _scrollToToday,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProgram,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _calendarDays.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No workout schedule available',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Program header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            border: Border(
                              bottom: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _programName ?? 'Current Program',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_startDate != null)
                                      Text(
                                        _formatStartDateLabel(_startDate),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_weeks.length} weeks',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Calendar list
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _calendarDays.length,
                            itemBuilder: (context, index) {
                              final item = _calendarDays[index];
                              return _buildDayCard(theme, item, index);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  String _formatStartDateLabel(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(date.year, date.month, date.day);
    final formatted = DateFormat('MMM d, yyyy').format(date);

    if (startDay.isAfter(today)) {
      return 'Starts on $formatted';
    } else {
      return 'Started $formatted';
    }
  }

  Widget _buildDayCard(ThemeData theme, CalendarDayItem item, int index) {
    // Check if this is the first day of a new week
    final isNewWeek = index == 0 || _calendarDays[index - 1].weekNumber != item.weekNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week header
        if (isNewWeek) ...[
          if (index > 0) const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Week ${item.weekNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Day card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: item.isMissed
                ? Colors.red.withValues(alpha: 0.05)
                : item.isToday
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : item.isPast
                        ? theme.cardColor.withValues(alpha: 0.5)
                        : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isMissed
                  ? Colors.red.withValues(alpha: 0.5)
                  : item.isToday
                      ? theme.colorScheme.primary
                      : item.isPast
                          ? theme.dividerColor.withValues(alpha: 0.5)
                          : theme.dividerColor,
              width: item.isMissed ? 2 : (item.isToday ? 2 : 1),
            ),
          ),
          child: InkWell(
            onTap: () => _showDayDetail(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Date column
                  Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: item.isToday
                          ? theme.colorScheme.primary
                          : item.workout?.isRestDay == true
                              ? Colors.grey.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE').format(item.date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: item.isToday ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        Text(
                          DateFormat('d').format(item.date),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: item.isToday ? Colors.white : null,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(item.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: item.isToday ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Workout info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Day ${item.programDayNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: item.isPast && !item.isToday ? Colors.grey : null,
                              ),
                            ),
                            if (item.isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (item.isMissed) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MISSED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (item.workout?.isRestDay == true)
                          Row(
                            children: [
                              Icon(Icons.bed, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                'Rest Day',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          )
                        else if (item.workout != null) ...[
                          Text(
                            item.workout!.name,
                            style: TextStyle(
                              color: item.isPast && !item.isToday
                                  ? Colors.grey[500]
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.workout!.exercises.length} exercises',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Arrow indicator
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDayDetail(CalendarDayItem item) {
    final theme = Theme.of(context);
    final weekIndex = item.weekNumber - 1;
    final dayIndex = item.dayInWeek;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            // Get the current workout from _weeks (may have been edited)
            final currentWorkout = weekIndex < _weeks.length && dayIndex < _weeks[weekIndex].days.length
                ? _weeks[weekIndex].days[dayIndex]
                : item.workout;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: currentWorkout?.isRestDay == true
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              currentWorkout?.isRestDay == true
                                  ? Icons.bed
                                  : Icons.fitness_center,
                              color: currentWorkout?.isRestDay == true
                                  ? Colors.grey
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: _isTrainerMode && currentWorkout?.isRestDay != true
                                      ? () {
                                          Navigator.pop(sheetContext);
                                          _showEditDayNameDialog(weekIndex, dayIndex, currentWorkout!);
                                        }
                                      : null,
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Day ${item.programDayNumber} - ${currentWorkout?.name ?? "Workout"}',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (_isTrainerMode && currentWorkout?.isRestDay != true) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(item.date),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          if (_isTrainerMode && currentWorkout?.isRestDay != true)
                            IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: 'Add exercise',
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _showAddExerciseDialog(weekIndex, dayIndex);
                              },
                            ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    // Content
                    Expanded(
                      child: currentWorkout?.isRestDay == true
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.self_improvement, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Rest & Recovery',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Take this day to rest and let your muscles recover.',
                                    style: TextStyle(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: currentWorkout?.exercises.length ?? 0,
                              itemBuilder: (context, index) {
                                final exercise = currentWorkout!.exercises[index];
                                final exercises = currentWorkout!.exercises;
                                final isInSuperset = exercise.isInSuperset;

                                // Check superset position
                                final isFirstInSuperset = isInSuperset &&
                                    (index == 0 || exercises[index - 1].supersetGroupId != exercise.supersetGroupId);
                                final isLastInSuperset = isInSuperset &&
                                    (index == exercises.length - 1 || exercises[index + 1].supersetGroupId != exercise.supersetGroupId);
                                final isMiddleInSuperset = isInSuperset && !isFirstInSuperset && !isLastInSuperset;

                                return InkWell(
                                  onTap: _isTrainerMode
                                      ? () {
                                          Navigator.pop(sheetContext);
                                          _showEditExerciseDialog(exercise, weekIndex, dayIndex);
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      bottom: isInSuperset && !isLastInSuperset ? 0 : 12,
                                      left: isInSuperset ? 8 : 0,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(isMiddleInSuperset || isLastInSuperset ? 0 : 12),
                                        topRight: Radius.circular(isMiddleInSuperset || isLastInSuperset ? 0 : 12),
                                        bottomLeft: Radius.circular(isMiddleInSuperset || isFirstInSuperset ? 0 : 12),
                                        bottomRight: Radius.circular(isMiddleInSuperset || isFirstInSuperset ? 0 : 12),
                                      ),
                                      border: Border.all(
                                        color: isInSuperset
                                            ? theme.colorScheme.secondary
                                            : theme.dividerColor,
                                        width: isInSuperset ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Superset indicator or number
                                        if (isInSuperset)
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.link,
                                                size: 20,
                                                color: theme.colorScheme.secondary,
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      exercise.exerciseName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isFirstInSuperset)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                              const SizedBox(height: 2),
                                              Text(
                                                exercise.muscleGroup,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isInSuperset
                                                ? theme.colorScheme.secondary.withValues(alpha: 0.15)
                                                : theme.colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${exercise.sets} × ${exercise.reps}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isInSuperset
                                                  ? theme.colorScheme.secondary
                                                  : theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        if (_isTrainerMode) ...[
                                          const SizedBox(width: 8),
                                          Icon(Icons.edit, size: 18, color: Colors.grey[400]),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Mark as Missed button for past days (trainer mode only)
                    if (_isTrainerMode && item.isPast && !item.isToday && !item.isMissed)
                      Container(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: MediaQuery.of(sheetContext).padding.bottom + 16,
                          top: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: theme.dividerColor)),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showMarkMissedDialog(item);
                          },
                          icon: const Icon(Icons.event_busy),
                          label: const Text('Mark as Missed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showMarkMissedDialog(CalendarDayItem item) {
    final theme = Theme.of(context);
    final dateStr = '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';

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
            Icon(Icons.event_busy, size: 48, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              'Mark Day ${item.programDayNumber} as Missed?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how to handle the missed workout:',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Skip option
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _markDayAsMissed(dateStr, 'skip');
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Skip this workout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Mark as missed, schedule stays the same',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Push option
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _markDayAsMissed(dateStr, 'push');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Column(
                children: [
                  Text(
                    'Push remaining workouts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Shift all future workouts by 1 day',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markDayAsMissed(String dateStr, String action) async {
    if (_programId == null) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.post(
        ApiConstants.markMissedDay(_programId!),
        data: {
          'date': dateStr,
          'action': action,
        },
      );

      // Reload the program to get updated data
      await _loadProgram();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'push'
                  ? 'Day marked as missed. All workouts pushed by 1 day.'
                  : 'Day marked as missed.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark day as missed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditExerciseDialog(WorkoutExercise exercise, int weekIndex, int dayIndex) {
    WorkoutExercise currentExercise = exercise;
    int sets = exercise.sets;
    int reps = _parseRepsToInt(exercise.reps);
    bool applyToAllWeeks = true;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) {
          final bottomPadding = MediaQuery.of(dialogContext).viewInsets.bottom + MediaQuery.of(dialogContext).padding.bottom + 24;

          void showReplacePicker() {
            String search = '';
            showModalBottomSheet(
              context: dialogContext,
              isScrollControlled: true,
              builder: (pickerContext) => StatefulBuilder(
                builder: (pickerContext, setPickerState) {
                  final filtered = _exerciseLibrary.where((e) => search.isEmpty || e['name'].toString().toLowerCase().contains(search.toLowerCase())).toList();
                  return DraggableScrollableSheet(
                    initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
                    builder: (context, scrollController) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(children: [
                            Text('Replace Exercise', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            TextField(decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v) => setPickerState(() => search = v)),
                          ]),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final e = filtered[i];
                              return ListTile(
                                title: Text(e['name'] as String),
                                subtitle: Text(e['muscle'] as String),
                                trailing: const Icon(Icons.check),
                                onTap: () {
                                  Navigator.pop(pickerContext);
                                  setModalState(() {
                                    currentExercise = WorkoutExercise(
                                      exerciseId: e['id'] as int,
                                      exerciseName: e['name'] as String,
                                      muscleGroup: e['muscle'] as String,
                                      sets: sets,
                                      reps: reps.toString(),
                                    );
                                  });
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

          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomPadding),
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
                    Expanded(child: Text(currentExercise.exerciseName, style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                    IconButton(onPressed: showReplacePicker, icon: const Icon(Icons.swap_horiz), style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1), foregroundColor: Colors.blue)),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _removeExercise(exercise, weekIndex, dayIndex);
                      },
                      icon: const Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.1), foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close), style: IconButton.styleFrom(backgroundColor: Colors.grey.withValues(alpha: 0.1), foregroundColor: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(children: [const SizedBox(width: 60, child: Text('Sets:')), Expanded(child: Slider(value: sets.toDouble(), min: 1, max: 8, divisions: 7, onChanged: (v) => setModalState(() => sets = v.round()))), SizedBox(width: 40, child: Text('$sets', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center))]),
                Row(children: [const SizedBox(width: 60, child: Text('Reps:')), Expanded(child: Slider(value: reps.toDouble(), min: 1, max: 30, divisions: 29, onChanged: (v) => setModalState(() => reps = v.round()))), SizedBox(width: 40, child: Text('$reps', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center))]),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => applyToAllWeeks = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !applyToAllWeeks ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                            border: Border.all(
                              color: !applyToAllWeeks ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                              width: !applyToAllWeeks ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'This Week',
                              style: TextStyle(
                                color: !applyToAllWeeks ? theme.colorScheme.primary : null,
                                fontWeight: !applyToAllWeeks ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => applyToAllWeeks = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: applyToAllWeeks ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                            border: Border.all(
                              color: applyToAllWeeks ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                              width: applyToAllWeeks ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'All Weeks',
                              style: TextStyle(
                                color: applyToAllWeeks ? theme.colorScheme.primary : null,
                                fontWeight: applyToAllWeeks ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final wasReplaced = currentExercise.exerciseId != exercise.exerciseId;
                      final updatedExercise = currentExercise.copyWith(sets: sets, reps: reps.toString());

                      if (wasReplaced) {
                        if (applyToAllWeeks) {
                          _replaceExerciseAllWeeks(exercise, updatedExercise, dayIndex);
                        } else {
                          _replaceExerciseInWeek(exercise, updatedExercise, weekIndex, dayIndex);
                        }
                      } else {
                        if (applyToAllWeeks) {
                          _updateExerciseAllWeeks(exercise, dayIndex, sets, reps);
                        } else {
                          _updateExerciseInWeek(exercise, weekIndex, dayIndex, sets, reps);
                        }
                      }
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditDayNameDialog(int weekIndex, int dayIndex, WorkoutDay day) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: day.name);
    bool applyToAllWeeks = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) {
          final bottomPadding = MediaQuery.of(dialogContext).viewInsets.bottom + MediaQuery.of(dialogContext).padding.bottom + 24;

          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                        'Edit Day Name',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Day Name',
                    hintText: 'e.g., Push Day, Circuit A',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                // This Week / All Weeks toggle buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => applyToAllWeeks = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !applyToAllWeeks ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                            border: Border.all(
                              color: !applyToAllWeeks ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                              width: !applyToAllWeeks ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'This Week',
                              style: TextStyle(
                                color: !applyToAllWeeks ? theme.colorScheme.primary : null,
                                fontWeight: !applyToAllWeeks ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => applyToAllWeeks = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: applyToAllWeeks ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                            border: Border.all(
                              color: applyToAllWeeks ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                              width: applyToAllWeeks ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'All Weeks',
                              style: TextStyle(
                                color: applyToAllWeeks ? theme.colorScheme.primary : null,
                                fontWeight: applyToAllWeeks ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final newName = controller.text.trim();
                      if (newName.isEmpty) return;
                      Navigator.pop(dialogContext);
                      if (applyToAllWeeks) {
                        _updateDayNameAllWeeks(weekIndex, dayIndex, day.name, newName);
                      } else {
                        _updateDayName(weekIndex, dayIndex, newName);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateDayName(int weekIndex, int dayIndex, String newName) {
    setState(() {
      final week = _weeks[weekIndex];
      final day = week.days[dayIndex];
      final days = List<WorkoutDay>.from(week.days);
      days[dayIndex] = day.copyWith(name: newName);
      _weeks[weekIndex] = week.copyWith(days: days);
      _hasChanges = true;
      _buildCalendarDays();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Renamed to "$newName"')),
    );
  }

  void _updateDayNameAllWeeks(int weekIndex, int dayIndex, String oldName, String newName) {
    setState(() {
      for (int i = 0; i < _weeks.length; i++) {
        final week = _weeks[i];
        if (dayIndex >= week.days.length) continue;

        final day = week.days[dayIndex];
        // Only update if the day has the same name (to avoid changing unrelated days)
        if (day.name == oldName) {
          final days = List<WorkoutDay>.from(week.days);
          days[dayIndex] = day.copyWith(name: newName);
          _weeks[i] = week.copyWith(days: days);
        }
      }
      _hasChanges = true;
      _buildCalendarDays();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Renamed to "$newName" in all weeks')),
    );
  }

  void _showAddExerciseDialog(int weekIndex, int dayIndex) {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (pickerContext) => StatefulBuilder(
        builder: (pickerContext, setModalState) {
          final filtered = _exerciseLibrary.where((e) => search.isEmpty || e['name'].toString().toLowerCase().contains(search.toLowerCase())).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Text('Add Exercise', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                      return ListTile(
                        title: Text(e['name'] as String),
                        subtitle: Text(e['muscle'] as String),
                        trailing: const Icon(Icons.add),
                        onTap: () {
                          Navigator.pop(pickerContext);
                          _showAddExerciseSettingsDialog(e, weekIndex, dayIndex);
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

  void _showAddExerciseSettingsDialog(Map<String, dynamic> exerciseData, int weekIndex, int dayIndex) {
    int sets = 3;
    int reps = 10;
    bool applyToAllWeeks = true;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) {
          final bottomPadding = MediaQuery.of(dialogContext).viewInsets.bottom + MediaQuery.of(dialogContext).padding.bottom + 24;

          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomPadding),
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
                        exerciseData['name'] as String,
                        style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey.withValues(alpha: 0.1), foregroundColor: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  exerciseData['muscle'] as String,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  const SizedBox(width: 60, child: Text('Sets:')),
                  Expanded(child: Slider(value: sets.toDouble(), min: 1, max: 8, divisions: 7, onChanged: (v) => setModalState(() => sets = v.round()))),
                  SizedBox(width: 40, child: Text('$sets', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center)),
                ]),
                Row(children: [
                  const SizedBox(width: 60, child: Text('Reps:')),
                  Expanded(child: Slider(value: reps.toDouble(), min: 1, max: 30, divisions: 29, onChanged: (v) => setModalState(() => reps = v.round()))),
                  SizedBox(width: 40, child: Text('$reps', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center)),
                ]),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => applyToAllWeeks = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !applyToAllWeeks ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                            border: Border.all(
                              color: !applyToAllWeeks ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                              width: !applyToAllWeeks ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'This Week',
                              style: TextStyle(
                                color: !applyToAllWeeks ? theme.colorScheme.primary : null,
                                fontWeight: !applyToAllWeeks ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => applyToAllWeeks = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: applyToAllWeeks ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                            border: Border.all(
                              color: applyToAllWeeks ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                              width: applyToAllWeeks ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'All Weeks',
                              style: TextStyle(
                                color: applyToAllWeeks ? theme.colorScheme.primary : null,
                                fontWeight: applyToAllWeeks ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (applyToAllWeeks) {
                        _addExerciseAllWeeks(exerciseData, dayIndex, sets, reps);
                      } else {
                        _addExercise(exerciseData, weekIndex, dayIndex, sets, reps);
                      }
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Add Exercise'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateExerciseInWeek(WorkoutExercise exercise, int weekIndex, int dayIndex, int sets, int reps) {
    setState(() {
      final week = _weeks[weekIndex];
      final day = week.days[dayIndex];
      final updated = day.exercises.map((e) => e.exerciseName == exercise.exerciseName ? e.copyWith(sets: sets, reps: reps.toString()) : e).toList();
      final days = List<WorkoutDay>.from(week.days);
      days[dayIndex] = day.copyWith(exercises: updated);
      _weeks[weekIndex] = week.copyWith(days: days);
      _hasChanges = true;
    });
    _buildCalendarDays();
  }

  void _updateExerciseAllWeeks(WorkoutExercise exercise, int dayIndex, int sets, int reps) {
    setState(() {
      for (int weekIndex = 0; weekIndex < _weeks.length; weekIndex++) {
        final week = _weeks[weekIndex];
        if (dayIndex >= week.days.length) continue;

        final day = week.days[dayIndex];
        final updated = day.exercises.map((e) => e.exerciseName == exercise.exerciseName ? e.copyWith(sets: sets, reps: reps.toString()) : e).toList();
        final days = List<WorkoutDay>.from(week.days);
        days[dayIndex] = day.copyWith(exercises: updated);
        _weeks[weekIndex] = week.copyWith(days: days);
      }
      _hasChanges = true;
    });
    _buildCalendarDays();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated in all weeks')));
  }

  void _replaceExerciseInWeek(WorkoutExercise oldExercise, WorkoutExercise newExercise, int weekIndex, int dayIndex) {
    setState(() {
      final week = _weeks[weekIndex];
      final day = week.days[dayIndex];
      final updated = day.exercises.map((e) => e.exerciseName == oldExercise.exerciseName ? newExercise : e).toList();
      final days = List<WorkoutDay>.from(week.days);
      days[dayIndex] = day.copyWith(exercises: updated);
      _weeks[weekIndex] = week.copyWith(days: days);
      _hasChanges = true;
    });
    _buildCalendarDays();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Replaced with ${newExercise.exerciseName}')));
  }

  void _replaceExerciseAllWeeks(WorkoutExercise oldExercise, WorkoutExercise newExercise, int dayIndex) {
    setState(() {
      for (int weekIndex = 0; weekIndex < _weeks.length; weekIndex++) {
        final week = _weeks[weekIndex];
        if (dayIndex >= week.days.length) continue;

        final day = week.days[dayIndex];
        final updated = day.exercises.map((e) => e.exerciseName == oldExercise.exerciseName ? newExercise : e).toList();
        final days = List<WorkoutDay>.from(week.days);
        days[dayIndex] = day.copyWith(exercises: updated);
        _weeks[weekIndex] = week.copyWith(days: days);
      }
      _hasChanges = true;
    });
    _buildCalendarDays();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Replaced with ${newExercise.exerciseName} in all weeks')));
  }

  void _addExercise(Map<String, dynamic> data, int weekIndex, int dayIndex, int sets, int reps) {
    setState(() {
      final week = _weeks[weekIndex];
      final day = week.days[dayIndex];
      final newEx = WorkoutExercise(
        exerciseId: data['id'] as int,
        exerciseName: data['name'] as String,
        muscleGroup: data['muscle'] as String,
        sets: sets,
        reps: reps.toString(),
      );
      final days = List<WorkoutDay>.from(week.days);
      days[dayIndex] = day.copyWith(exercises: [...day.exercises, newEx]);
      _weeks[weekIndex] = week.copyWith(days: days);
      _hasChanges = true;
    });
    _buildCalendarDays();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${data['name']}')));
  }

  void _addExerciseAllWeeks(Map<String, dynamic> data, int dayIndex, int sets, int reps) {
    setState(() {
      for (int weekIndex = 0; weekIndex < _weeks.length; weekIndex++) {
        final week = _weeks[weekIndex];
        if (dayIndex >= week.days.length) continue;
        final day = week.days[dayIndex];
        final newEx = WorkoutExercise(
          exerciseId: data['id'] as int,
          exerciseName: data['name'] as String,
          muscleGroup: data['muscle'] as String,
          sets: sets,
          reps: reps.toString(),
        );
        final days = List<WorkoutDay>.from(week.days);
        days[dayIndex] = day.copyWith(exercises: [...day.exercises, newEx]);
        _weeks[weekIndex] = week.copyWith(days: days);
      }
      _hasChanges = true;
    });
    _buildCalendarDays();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${data['name']} to all weeks')));
  }

  /// Parse a reps string (e.g. "8-10" or "12") into an integer for slider UI.
  /// For ranges, returns the upper bound.
  int _parseRepsToInt(String reps) {
    if (reps.contains('-')) {
      final parts = reps.split('-');
      return int.tryParse(parts.last.trim()) ?? 10;
    }
    return int.tryParse(reps) ?? 10;
  }

  void _removeExercise(WorkoutExercise exercise, int weekIndex, int dayIndex) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
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
            Icon(Icons.delete_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Remove "${exercise.exerciseName}"?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose where to remove this exercise from:',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        final week = _weeks[weekIndex];
                        final day = week.days[dayIndex];
                        final days = List<WorkoutDay>.from(week.days);
                        days[dayIndex] = day.copyWith(exercises: day.exercises.where((e) => e.exerciseName != exercise.exerciseName).toList());
                        _weeks[weekIndex] = week.copyWith(days: days);
                        _hasChanges = true;
                      });
                      _buildCalendarDays();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed ${exercise.exerciseName} from this week')));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('This Week'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        for (int wIdx = 0; wIdx < _weeks.length; wIdx++) {
                          final week = _weeks[wIdx];
                          if (dayIndex >= week.days.length) continue;
                          final day = week.days[dayIndex];
                          final days = List<WorkoutDay>.from(week.days);
                          days[dayIndex] = day.copyWith(exercises: day.exercises.where((e) => e.exerciseName != exercise.exerciseName).toList());
                          _weeks[wIdx] = week.copyWith(days: days);
                        }
                        _hasChanges = true;
                      });
                      _buildCalendarDays();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed ${exercise.exerciseName} from all weeks')));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('All Weeks'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
