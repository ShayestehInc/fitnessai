import 'package:health/health.dart';
import 'dart:async';

/// Service for syncing health data from HealthKit/Health Connect
/// Runs in background to avoid blocking UI thread
class HealthService {
  static Health? _health;
  static Health get health => _health ??= Health();

  /// Request permissions for health data access
  Future<bool> requestPermissions() async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.HEART_RATE,
      ];

      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];

      return await health.requestAuthorization(types, permissions: permissions);
    } catch (e) {
      return false;
    }
  }

  /// Get today's steps
  Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final steps = await health.getHealthDataFromTypes(
        [HealthDataType.STEPS],
        today,
        now,
      );

      if (steps.isEmpty) return 0;

      int totalSteps = 0;
      for (var data in steps) {
        if (data is NumericHealthValue) {
          totalSteps += data.numericValue.toInt();
        }
      }

      return totalSteps;
    } catch (e) {
      return 0;
    }
  }

  /// Get last night's sleep hours
  Future<double> getLastNightSleep() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 20, 0);
      final endOfToday = DateTime(now.year, now.month, now.day, 12, 0);

      final sleepData = await health.getHealthDataFromTypes(
        [HealthDataType.SLEEP_IN_BED],
        startOfYesterday,
        endOfToday,
      );

      if (sleepData.isEmpty) return 0.0;

      double totalHours = 0.0;
      for (var data in sleepData) {
        if (data is HealthDataPoint) {
          final duration = data.dateTo.difference(data.dateFrom);
          totalHours += duration.inMinutes / 60.0;
        }
      }

      return totalHours;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get resting heart rate (latest)
  Future<int?> getRestingHeartRate() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final heartRateData = await health.getHealthDataFromTypes(
        [HealthDataType.HEART_RATE],
        weekAgo,
        now,
      );

      if (heartRateData.isEmpty) return null;

      // Get the most recent resting heart rate
      HealthDataPoint? latest;
      for (var data in heartRateData) {
        if (data is HealthDataPoint) {
          if (latest == null || data.dateFrom.isAfter(latest.dateFrom)) {
            latest = data;
          }
        }
      }

      if (latest is NumericHealthValue) {
        return latest.numericValue.toInt();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sync all health data for today
  Future<Map<String, dynamic>> syncTodayHealthData() async {
    final steps = await getTodaySteps();
    final sleep = await getLastNightSleep();
    final heartRate = await getRestingHeartRate();

    return {
      'steps': steps,
      'sleep_hours': sleep,
      'resting_heart_rate': heartRate,
    };
  }
}
