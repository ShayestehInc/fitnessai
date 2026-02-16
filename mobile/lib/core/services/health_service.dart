import 'dart:async';
import 'dart:io' show Platform;

import 'package:health/health.dart';

import '../models/health_metrics.dart';

/// Service for reading health data from HealthKit (iOS) / Health Connect (Android).
///
/// This service is read-only -- it never writes health data back.
/// Each data type fetch is independently try-caught so partial data is valid.
class HealthService {
  static Health? _health;
  static Health get health => _health ??= Health();

  /// The data types we request read access for.
  static const List<HealthDataType> _requestedTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
  ];

  /// Request read-only permissions for all health data types.
  ///
  /// Returns true if authorization was granted (or already granted).
  /// Returns false if denied, or if the platform does not support health data.
  Future<bool> requestPermissions() async {
    try {
      final permissions = List<HealthDataAccess>.filled(
        _requestedTypes.length,
        HealthDataAccess.READ,
      );
      return await health.requestAuthorization(
        _requestedTypes,
        permissions: permissions,
      );
    } catch (_) {
      return false;
    }
  }

  /// Check whether health data is available on this platform.
  ///
  /// Returns false on simulators, unsupported Android devices,
  /// or any platform that does not support the health package.
  Future<bool> checkPermissionStatus() async {
    try {
      // hasPermissions returns a bool? -- null means unknown/unavailable
      final result = await health.hasPermissions(_requestedTypes);
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all health metrics for today and return a typed [HealthMetrics].
  ///
  /// Each metric type is fetched independently. If one type fails,
  /// the others still return valid data. This method never throws.
  Future<HealthMetrics> syncTodayHealthData() async {
    final steps = await getTodaySteps();
    final activeCalories = await getTodayActiveCalories();
    final heartRate = await getLatestHeartRate();
    final weightResult = await getLatestWeight();

    return HealthMetrics(
      steps: steps,
      activeCalories: activeCalories,
      heartRate: heartRate,
      latestWeightKg: weightResult?.$1,
      weightDate: weightResult?.$2,
    );
  }

  /// Get total steps from midnight today to now.
  Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final dataPoints = await health.getHealthDataFromTypes(
        startTime: todayMidnight,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      if (dataPoints.isEmpty) return 0;

      int totalSteps = 0;
      for (final point in dataPoints) {
        if (point.value is NumericHealthValue) {
          totalSteps +=
              (point.value as NumericHealthValue).numericValue.toInt();
        }
      }
      return totalSteps;
    } catch (_) {
      return 0;
    }
  }

  /// Get total active calories burned from midnight today to now.
  Future<int> getTodayActiveCalories() async {
    try {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final dataPoints = await health.getHealthDataFromTypes(
        startTime: todayMidnight,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      if (dataPoints.isEmpty) return 0;

      double totalCalories = 0;
      for (final point in dataPoints) {
        if (point.value is NumericHealthValue) {
          totalCalories +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      return totalCalories.round();
    } catch (_) {
      return 0;
    }
  }

  /// Get the latest heart rate reading from the past 24 hours.
  ///
  /// Returns null if no heart rate data is available.
  Future<int?> getLatestHeartRate() async {
    try {
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(hours: 24));

      final dataPoints = await health.getHealthDataFromTypes(
        startTime: dayAgo,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      if (dataPoints.isEmpty) return null;

      // Find the most recent reading by dateFrom
      HealthDataPoint? latest;
      for (final point in dataPoints) {
        if (latest == null || point.dateFrom.isAfter(latest.dateFrom)) {
          latest = point;
        }
      }

      if (latest != null && latest.value is NumericHealthValue) {
        return (latest.value as NumericHealthValue).numericValue.toInt();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get the most recent weight reading from the past 7 days.
  ///
  /// Returns a tuple of (weightKg, date) or null if no weight data exists.
  /// If multiple readings exist on the same day, the most recent by timestamp wins.
  Future<(double, DateTime)?> getLatestWeight() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final dataPoints = await health.getHealthDataFromTypes(
        startTime: weekAgo,
        endTime: now,
        types: [HealthDataType.WEIGHT],
      );

      if (dataPoints.isEmpty) return null;

      // Find the most recent weight reading by dateFrom timestamp
      HealthDataPoint? latest;
      for (final point in dataPoints) {
        if (latest == null || point.dateFrom.isAfter(latest.dateFrom)) {
          latest = point;
        }
      }

      if (latest != null && latest.value is NumericHealthValue) {
        final weightKg =
            (latest.value as NumericHealthValue).numericValue.toDouble();
        return (weightKg, latest.dateFrom);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Open the device's health app settings.
  ///
  /// Returns the platform-specific URI string.
  static String get healthSettingsUri {
    if (Platform.isIOS) {
      return 'x-apple-health://';
    }
    // Android Health Connect
    return 'market://details?id=com.google.android.apps.healthdata';
  }
}
