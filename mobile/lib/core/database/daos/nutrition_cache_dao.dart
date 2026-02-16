import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'nutrition_cache_dao.g.dart';

@DriftAccessor(tables: [PendingNutritionLogs, PendingWeightCheckins])
class NutritionCacheDao extends DatabaseAccessor<AppDatabase>
    with _$NutritionCacheDaoMixin {
  NutritionCacheDao(super.db);

  // -- Nutrition Logs --

  /// Insert a pending nutrition log.
  Future<int> insertPendingNutrition({
    required String clientId,
    required int userId,
    required String parsedDataJson,
    required String targetDate,
  }) {
    return into(pendingNutritionLogs).insert(
      PendingNutritionLogsCompanion.insert(
        clientId: clientId,
        userId: userId,
        parsedDataJson: parsedDataJson,
        targetDate: targetDate,
      ),
    );
  }

  /// Get all pending nutrition logs for a user on a specific date.
  Future<List<PendingNutritionLog>> getPendingNutritionForDate(
    int userId,
    String date,
  ) {
    final query = select(pendingNutritionLogs)
      ..where((t) =>
          t.userId.equals(userId) & t.targetDate.equals(date))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Get all pending nutrition logs for a user.
  Future<List<PendingNutritionLog>> getPendingNutrition(int userId) {
    final query = select(pendingNutritionLogs)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Get all pending nutrition logs for a user on a specific date (AC-21 alias).
  Future<List<PendingNutritionLog>> getPendingNutritionForUser(
    int userId,
    String date,
  ) {
    return getPendingNutritionForDate(userId, date);
  }

  /// Delete a pending nutrition log by clientId.
  Future<void> deleteNutritionByClientId(String clientId) {
    return (delete(pendingNutritionLogs)
          ..where((t) => t.clientId.equals(clientId)))
        .go();
  }

  /// Delete all pending nutrition for a user.
  Future<void> deleteAllNutritionForUser(int userId) {
    return (delete(pendingNutritionLogs)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  // -- Weight Check-ins --

  /// Insert a pending weight check-in.
  Future<int> insertPendingWeight({
    required String clientId,
    required int userId,
    required String date,
    required double weightKg,
    String notes = '',
  }) {
    return into(pendingWeightCheckins).insert(
      PendingWeightCheckinsCompanion.insert(
        clientId: clientId,
        userId: userId,
        date: date,
        weightKg: weightKg,
        notes: Value(notes),
      ),
    );
  }

  /// Get all pending weight check-ins for a user.
  Future<List<PendingWeightCheckin>> getPendingWeightCheckins(int userId) {
    final query = select(pendingWeightCheckins)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Get all pending weight check-ins for a user (AC-21 alias).
  Future<List<PendingWeightCheckin>> getPendingWeightForUser(int userId) {
    return getPendingWeightCheckins(userId);
  }

  /// Delete a pending weight check-in by clientId.
  Future<void> deleteWeightByClientId(String clientId) {
    return (delete(pendingWeightCheckins)
          ..where((t) => t.clientId.equals(clientId)))
        .go();
  }

  /// Delete all pending weight check-ins for a user.
  Future<void> deleteAllWeightForUser(int userId) {
    return (delete(pendingWeightCheckins)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }
}
