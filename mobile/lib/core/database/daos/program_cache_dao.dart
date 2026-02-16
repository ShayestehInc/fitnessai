import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'program_cache_dao.g.dart';

@DriftAccessor(tables: [CachedPrograms])
class ProgramCacheDao extends DatabaseAccessor<AppDatabase>
    with _$ProgramCacheDaoMixin {
  ProgramCacheDao(super.db);

  /// Save or update cached programs for a user.
  /// Overwrites any existing cache entry for this user.
  Future<void> cachePrograms({
    required int userId,
    required String programsJson,
  }) async {
    // Delete existing cache for this user first (overwrite, not append)
    await (delete(cachedPrograms)
          ..where((t) => t.userId.equals(userId)))
        .go();

    await into(cachedPrograms).insert(
      CachedProgramsCompanion.insert(
        userId: userId,
        programsJson: programsJson,
      ),
    );
  }

  /// Get cached programs for a user. Returns null if no cache exists.
  Future<CachedProgram?> getCachedPrograms(int userId) {
    final query = select(cachedPrograms)
      ..where((t) => t.userId.equals(userId))
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// Delete stale caches older than the given duration.
  Future<int> deleteStaleCache(Duration maxAge) {
    final cutoff = DateTime.now().subtract(maxAge);
    return (delete(cachedPrograms)
          ..where((t) => t.cachedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Delete all cached programs for a user (logout cleanup).
  Future<void> deleteAllForUser(int userId) {
    return (delete(cachedPrograms)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }
}
