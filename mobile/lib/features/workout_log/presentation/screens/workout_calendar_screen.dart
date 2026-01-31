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

  CalendarDayItem({
    required this.date,
    required this.programDayNumber,
    required this.weekNumber,
    required this.dayInWeek,
    this.workout,
    required this.isToday,
    required this.isPast,
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
  String? _error;
  String? _programName;
  DateTime? _startDate;
  List<ProgramWeek> _weeks = [];
  List<CalendarDayItem> _calendarDays = [];
  final ScrollController _scrollController = ScrollController();

  bool get _isTrainerMode => widget.traineeId != null;

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

        _calendarDays.add(CalendarDayItem(
          date: date,
          programDayNumber: programDayNumber,
          weekNumber: week.weekNumber,
          dayInWeek: dayIndex,
          workout: day,
          isToday: dateOnly == today,
          isPast: dateOnly.isBefore(today),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isTrainerMode
            ? "${widget.traineeName ?? 'Trainee'}'s Schedule"
            : 'Workout Schedule'),
        actions: [
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
                                        'Started ${DateFormat('MMM d, yyyy').format(_startDate!)}',
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
            color: item.isToday
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : item.isPast
                    ? theme.cardColor.withValues(alpha: 0.5)
                    : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isToday
                  ? theme.colorScheme.primary
                  : item.isPast
                      ? theme.dividerColor.withValues(alpha: 0.5)
                      : theme.dividerColor,
              width: item.isToday ? 2 : 1,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                          color: item.workout?.isRestDay == true
                              ? Colors.grey.withValues(alpha: 0.1)
                              : theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.workout?.isRestDay == true
                              ? Icons.bed
                              : Icons.fitness_center,
                          color: item.workout?.isRestDay == true
                              ? Colors.grey
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${item.programDayNumber} - ${item.workout?.name ?? "Workout"}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(item.date),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor),
                // Content
                Expanded(
                  child: item.workout?.isRestDay == true
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
                          itemCount: item.workout?.exercises.length ?? 0,
                          itemBuilder: (context, index) {
                            final exercise = item.workout!.exercises[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                children: [
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
                                        Text(
                                          exercise.exerciseName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
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
                                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${exercise.sets} × ${exercise.reps}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
