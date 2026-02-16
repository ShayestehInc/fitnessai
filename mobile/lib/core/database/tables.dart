import 'package:drift/drift.dart';

/// Stores pending workout logs that haven't been synced to the server yet.
class PendingWorkoutLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  IntColumn get userId => integer()();
  TextColumn get workoutSummaryJson => text()();
  TextColumn get surveyDataJson => text()();
  TextColumn get readinessSurveyJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Stores pending nutrition logs that haven't been synced to the server yet.
class PendingNutritionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  IntColumn get userId => integer()();
  TextColumn get parsedDataJson => text()();
  TextColumn get targetDate => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Stores pending weight check-ins that haven't been synced to the server yet.
class PendingWeightCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  IntColumn get userId => integer()();
  TextColumn get date => text()();
  RealColumn get weightKg => real()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Caches fetched programs for offline access.
class CachedPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  TextColumn get programsJson => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

/// The central sync queue that tracks all pending operations.
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  IntColumn get userId => integer()();
  TextColumn get operationType => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
