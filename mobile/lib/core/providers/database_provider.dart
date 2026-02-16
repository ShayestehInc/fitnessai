import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// Provides the Drift database singleton.
/// Must be overridden in ProviderScope at app startup.
/// The database is created lazily on first access and persists
/// for the lifetime of the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden in ProviderScope',
  );
});
