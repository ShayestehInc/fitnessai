import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
    state = AsyncData({...previous, category: enabled});

    try {
      final repo = ref.read(notificationPreferencesRepositoryProvider);
      final updated = await repo.updatePreference(category, enabled);
      state = AsyncData(updated);
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previous);
      rethrow;
    }
  }
}
