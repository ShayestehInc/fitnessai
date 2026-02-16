import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'workout_cache_dao.g.dart';

@DriftAccessor(tables: [PendingWorkoutLogs])
class WorkoutCacheDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutCacheDaoMixin {
  WorkoutCacheDao(super.db);

  /// Insert a pending workout log.
  Future<int> insertPendingWorkout({
    required String clientId,
    required int userId,
    required String workoutSummaryJson,
    required String surveyDataJson,
    String? readinessSurveyJson,
  }) {
    return into(pendingWorkoutLogs).insert(
      PendingWorkoutLogsCompanion.insert(
        clientId: clientId,
        userId: userId,
        workoutSummaryJson: workoutSummaryJson,
        surveyDataJson: surveyDataJson,
        readinessSurveyJson: Value(readinessSurveyJson),
      ),
    );
  }

  /// Get all pending workout logs for a user.
  Future<List<PendingWorkoutLog>> getPendingWorkouts(int userId) {
    final query = select(pendingWorkoutLogs)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Delete a pending workout by clientId (after successful sync).
  Future<void> deleteByClientId(String clientId) {
    return (delete(pendingWorkoutLogs)
          ..where((t) => t.clientId.equals(clientId)))
        .go();
  }

  /// Delete all pending workouts for a user (logout cleanup).
  Future<void> deleteAllForUser(int userId) {
    return (delete(pendingWorkoutLogs)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  /// Get all pending workout logs for a user (alias for AC-21).
  Future<List<PendingWorkoutLog>> getPendingWorkoutsForUser(int userId) {
    return getPendingWorkouts(userId);
  }

  /// Watch pending workout count for badges.
  Stream<int> watchPendingCount(int userId) {
    final query = selectOnly(pendingWorkoutLogs)
      ..addColumns([pendingWorkoutLogs.id.count()])
      ..where(pendingWorkoutLogs.userId.equals(userId));
    return query.watchSingle().map(
          (row) => row.read(pendingWorkoutLogs.id.count()) ?? 0,
        );
  }
}
