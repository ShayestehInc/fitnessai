/// Immutable data class representing a snapshot of today's health metrics
/// from HealthKit (iOS) or Health Connect (Android).
///
/// All numeric values are non-negative. Nullable fields indicate
/// that no data was available from the health platform.
class HealthMetrics {
  /// Total steps taken today (midnight to now).
  final int steps;

  /// Total active calories burned today (midnight to now).
  final int activeCalories;

  /// Most recent heart rate reading from the past 24 hours, or null if none.
  final int? heartRate;

  /// Most recent weight reading from the past 7 days in kg, or null if none.
  final double? latestWeightKg;

  /// Timestamp of the most recent weight reading, or null if none.
  final DateTime? weightDate;

  const HealthMetrics({
    required this.steps,
    required this.activeCalories,
    this.heartRate,
    this.latestWeightKg,
    this.weightDate,
  });

  /// A zero/empty metrics instance for initial or fallback state.
  static const empty = HealthMetrics(
    steps: 0,
    activeCalories: 0,
  );
}
