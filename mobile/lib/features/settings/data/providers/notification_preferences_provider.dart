import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart' show apiClientProvider;
import '../repositories/notification_preferences_repository.dart';

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
  return NotificationPreferencesRepository(ref.read(apiClientProvider));
});

final notificationPreferencesProvider = AsyncNotifierProvider<
    NotificationPreferencesNotifier, Map<String, bool>>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier
    extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    final repo = ref.read(notificationPreferencesRepositoryProvider);
    return repo.getPreferences();
  }

  Future<void> togglePreference(String category, bool enabled) async {
    final previous = state.valueOrNull;
    if (previous == null) return;

    // Optimistic update
    final optimistic = Map<String, bool>.from(previous);
    optimistic[category] = enabled;
    state = AsyncData(optimistic);

    try {
      final repo = ref.read(notificationPreferencesRepositoryProvider);
      final updated = await repo.updatePreference(category, enabled);
      state = AsyncData(updated);
    } catch (e) {
      // Rollback to previous data on failure. We rethrow so the caller
      // (_onToggle in the screen) can catch and show a user-facing toast.
      // Note: state is set to AsyncData (not AsyncError) so watchers only
      // see the rollback, not an error state.
      state = AsyncData(previous);
      rethrow;
    }
  }
}
