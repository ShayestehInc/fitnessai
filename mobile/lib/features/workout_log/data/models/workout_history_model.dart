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
  final Map<String, dynamic> workoutData;

  const WorkoutHistorySummary({
    required this.id,
    required this.date,
    required this.workoutName,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalVolumeLbs,
    required this.durationDisplay,
    required this.workoutData,
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
      workoutData: json['workout_data'] as Map<String, dynamic>? ?? {},
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

  /// Format volume for display (e.g., "12,500 lbs").
  String get formattedVolume {
    if (totalVolumeLbs <= 0) return '—';
    final rounded = totalVolumeLbs.round();
    // Add comma separators
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} lbs';
  }
}
