import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/workout_cache_dao.dart';
import 'daos/nutrition_cache_dao.dart';
import 'daos/program_cache_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PendingWorkoutLogs,
    PendingNutritionLogs,
    PendingWeightCheckins,
    CachedPrograms,
    SyncQueueItems,
  ],
  daos: [
    SyncQueueDao,
    WorkoutCacheDao,
    NutritionCacheDao,
    ProgramCacheDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// Run startup cleanup tasks:
  /// - Delete synced items older than 24 hours
  /// - Delete stale program caches older than 30 days
  ///
  /// Cleanup failures are non-fatal: the app should launch even
  /// if cleanup fails (e.g., corrupted DB, unexpected schema).
  Future<void> runStartupCleanup() async {
    try {
      await syncQueueDao.deleteOldSynced(const Duration(hours: 24));
      await programCacheDao.deleteStaleCache(const Duration(days: 30));
    } catch (e) {
      // Startup cleanup is best-effort. Log the error but don't
      // prevent the app from launching.
      assert(() {
        // Only in debug mode: surface the error during development
        debugPrint('Startup cleanup failed: $e');
        return true;
      }());
    }
  }

  /// Clear all data for a specific user (called on logout).
  Future<void> clearUserData(int userId) async {
    await syncQueueDao.deleteAllForUser(userId);
    await workoutCacheDao.deleteAllForUser(userId);
    await nutritionCacheDao.deleteAllNutritionForUser(userId);
    await nutritionCacheDao.deleteAllWeightForUser(userId);
    await programCacheDao.deleteAllForUser(userId);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fitnessai_offline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
