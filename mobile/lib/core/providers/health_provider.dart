import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../database/offline_weight_repository.dart';
import '../models/health_metrics.dart';
import '../services/health_service.dart';
import 'sync_provider.dart';

/// SharedPreferences keys for health permission state.
const String _kHealthPermissionAsked = 'health_permission_asked';
const String _kHealthPermissionGranted = 'health_permission_granted';

/// Represents the current state of the health data provider.
sealed class HealthDataState {
  const HealthDataState();
}

/// Initial state before any permission check or data fetch.
class HealthDataInitial extends HealthDataState {
  const HealthDataInitial();
}

/// Health data is currently being loaded.
class HealthDataLoading extends HealthDataState {
  const HealthDataLoading();
}

/// Health data has been successfully loaded.
class HealthDataLoaded extends HealthDataState {
  final HealthMetrics metrics;
  const HealthDataLoaded(this.metrics);
}

/// User denied health data permissions.
class HealthDataPermissionDenied extends HealthDataState {
  const HealthDataPermissionDenied();
}

/// Platform does not support health data (simulator, old Android, etc.).
class HealthDataUnavailable extends HealthDataState {
  const HealthDataUnavailable();
}

/// Manages health data state: permission handling, data fetching,
/// and weight auto-import.
class HealthDataNotifier extends StateNotifier<HealthDataState> {
  final HealthService _healthService;
  final OfflineWeightRepository? _weightRepo;
  final int? _userId;

  HealthDataNotifier({
    required HealthService healthService,
    OfflineWeightRepository? weightRepo,
    int? userId,
  })  : _healthService = healthService,
        _weightRepo = weightRepo,
        _userId = userId,
        super(const HealthDataInitial());

  /// Check persisted permission state and fetch data if previously granted.
  ///
  /// Returns true if health permission was previously granted (card should show).
  /// Returns false if permission was denied or not yet asked.
  Future<bool> checkAndRequestPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyAsked = prefs.getBool(_kHealthPermissionAsked) ?? false;
      final wasGranted = prefs.getBool(_kHealthPermissionGranted) ?? false;

      if (alreadyAsked && wasGranted) {
        // Permission was granted before -- fetch data directly
        await fetchHealthData();
        return true;
      }

      if (alreadyAsked && !wasGranted) {
        // User previously denied -- respect their choice
        state = const HealthDataPermissionDenied();
        return false;
      }

      // Not yet asked -- caller should show the permission sheet
      return false;
    } catch (_) {
      state = const HealthDataUnavailable();
      return false;
    }
  }

  /// Whether the user has already been asked about health permissions.
  Future<bool> wasPermissionAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kHealthPermissionAsked) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request OS-level health permissions and persist the result.
  ///
  /// Call this after the user taps "Connect Health" in the bottom sheet.
  /// Returns true if permission was granted.
  Future<bool> requestOsPermission() async {
    try {
      final granted = await _healthService.requestPermissions();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHealthPermissionAsked, true);
      await prefs.setBool(_kHealthPermissionGranted, granted);

      if (granted) {
        await fetchHealthData();
        return true;
      } else {
        state = const HealthDataPermissionDenied();
        return false;
      }
    } catch (_) {
      state = const HealthDataUnavailable();
      return false;
    }
  }

  /// Record that the user tapped "Not Now" on the permission sheet.
  Future<void> declinePermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHealthPermissionAsked, true);
      await prefs.setBool(_kHealthPermissionGranted, false);
      state = const HealthDataPermissionDenied();
    } catch (_) {
      state = const HealthDataPermissionDenied();
    }
  }

  /// Fetch today's health data from HealthKit / Health Connect.
  ///
  /// Updates state to [HealthDataLoaded] with the metrics.
  /// If the fetch fails entirely, sets state to [HealthDataUnavailable].
  Future<void> fetchHealthData() async {
    state = const HealthDataLoading();

    try {
      final metrics = await _healthService.syncTodayHealthData();
      state = HealthDataLoaded(metrics);

      // Auto-import weight in background (non-blocking)
      _autoImportWeight(metrics);
    } catch (_) {
      state = const HealthDataUnavailable();
    }
  }

  /// Auto-import weight from health data to WeightCheckIn if:
  /// 1. A weight reading exists for today
  /// 2. No check-in already exists for today (date-based dedup)
  /// 3. The weight repository is available
  Future<void> _autoImportWeight(HealthMetrics metrics) async {
    final weightRepo = _weightRepo;
    if (weightRepo == null || _userId == null) return;
    if (metrics.latestWeightKg == null || metrics.weightDate == null) return;

    final weightDate = metrics.weightDate!;
    final today = DateTime.now();

    // Only auto-import if the weight reading is from today
    if (weightDate.year != today.year ||
        weightDate.month != today.month ||
        weightDate.day != today.day) {
      return;
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    try {
      final result = await weightRepo.createWeightCheckIn(
        date: todayStr,
        weightKg: metrics.latestWeightKg!,
        notes: 'Auto-imported from Health',
      );

      // If there is already a check-in for today (manual or previous auto-import),
      // the server returns an error (409 conflict or validation error).
      // Either way, we silently ignore the failure. Manual entry takes priority.
      if (!result.success) {
        assert(() {
          debugPrint('Health weight auto-import skipped: ${result.error}');
          return true;
        }());
      }
    } catch (e) {
      // Silent failure for auto-import -- not critical functionality.
      assert(() {
        debugPrint('Health weight auto-import error: $e');
        return true;
      }());
    }
  }
}

/// Provides the [HealthDataNotifier] for the current user.
final healthDataProvider =
    StateNotifierProvider<HealthDataNotifier, HealthDataState>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  final weightRepo = ref.watch(offlineWeightRepositoryProvider);

  return HealthDataNotifier(
    healthService: HealthService(),
    weightRepo: weightRepo,
    userId: user?.id,
  );
});
