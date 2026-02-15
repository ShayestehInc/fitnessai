/// Model for a workout history summary item returned by the
/// `GET /api/workouts/daily-logs/workout-history/` endpoint.
class WorkoutHistorySummary {
  final int id;
  final String date;
  final String workoutName;
  final int exerciseCount;
  final int totalSets;
  final double totalVolumeLbs;
  final String durationDisplay;

  const WorkoutHistorySummary({
    required this.id,
    required this.date,
    required this.workoutName,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalVolumeLbs,
    required this.durationDisplay,
  });

  factory WorkoutHistorySummary.fromJson(Map<String, dynamic> json) {
    return WorkoutHistorySummary(
      id: json['id'] as int,
      date: json['date'] as String? ?? '',
      workoutName: json['workout_name'] as String? ?? 'Workout',
      exerciseCount: json['exercise_count'] as int? ?? 0,
      totalSets: json['total_sets'] as int? ?? 0,
      totalVolumeLbs: (json['total_volume_lbs'] as num?)?.toDouble() ?? 0.0,
      durationDisplay: json['duration_display'] as String? ?? '0:00',
    );
  }

  /// Format the date for display (e.g., "Mon, Feb 10").
  String get formattedDate {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final weekday = weekdays[parsed.weekday - 1];
    final month = months[parsed.month - 1];
    return '$weekday, $month ${parsed.day}';
  }

}
