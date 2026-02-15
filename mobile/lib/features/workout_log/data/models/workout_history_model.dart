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

  /// Format volume for display (e.g., "12,450 lbs").
  String get formattedVolume {
    if (totalVolumeLbs <= 0) return '0 lbs';
    final intVolume = totalVolumeLbs.round();
    // Add comma separators for thousands
    final str = intVolume.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return '$buffer lbs';
  }
}


/// Parsed workout detail data extracted from a raw workout_data JSON blob.
///
/// Centralises the JSON-shape-aware extraction logic so that widgets remain
/// purely presentational.
class WorkoutDetailData {
  final List<Map<String, dynamic>> exercises;
  final Map<String, dynamic>? readinessSurvey;
  final Map<String, dynamic>? postSurvey;

  const WorkoutDetailData({
    required this.exercises,
    this.readinessSurvey,
    this.postSurvey,
  });

  /// Parse a raw workout_data map into structured detail data.
  factory WorkoutDetailData.fromWorkoutData(Map<String, dynamic> data) {
    return WorkoutDetailData(
      exercises: _extractExercises(data),
      readinessSurvey: _extractReadinessSurvey(data),
      postSurvey: _extractPostSurvey(data),
    );
  }

  static List<Map<String, dynamic>> _extractExercises(
    Map<String, dynamic> data,
  ) {
    final exercises = data['exercises'];
    if (exercises is List) {
      return exercises.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  static Map<String, dynamic>? _extractReadinessSurvey(
    Map<String, dynamic> data,
  ) {
    final topLevel = data['readiness_survey'];
    if (topLevel is Map<String, dynamic> && topLevel.isNotEmpty) {
      if (topLevel.containsKey('survey_data') &&
          topLevel['survey_data'] is Map<String, dynamic>) {
        return topLevel['survey_data'] as Map<String, dynamic>;
      }
      return topLevel;
    }
    final sessions = data['sessions'];
    if (sessions is List && sessions.isNotEmpty) {
      final firstSession = sessions[0];
      if (firstSession is Map<String, dynamic>) {
        final sessionSurvey = firstSession['readiness_survey'];
        if (sessionSurvey is Map<String, dynamic> &&
            sessionSurvey.isNotEmpty) {
          if (sessionSurvey.containsKey('survey_data') &&
              sessionSurvey['survey_data'] is Map<String, dynamic>) {
            return sessionSurvey['survey_data'] as Map<String, dynamic>;
          }
          return sessionSurvey;
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? _extractPostSurvey(
    Map<String, dynamic> data,
  ) {
    final topLevel = data['post_survey'];
    if (topLevel is Map<String, dynamic> && topLevel.isNotEmpty) {
      return topLevel;
    }
    final sessions = data['sessions'];
    if (sessions is List && sessions.isNotEmpty) {
      final firstSession = sessions[0];
      if (firstSession is Map<String, dynamic>) {
        final sessionSurvey = firstSession['post_survey'];
        if (sessionSurvey is Map<String, dynamic> &&
            sessionSurvey.isNotEmpty) {
          return sessionSurvey;
        }
      }
    }
    return null;
  }
}
