import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';

/// Provides a singleton [HabitRepository] backed by the shared [ApiClient].
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HabitRepository(apiClient);
});

/// Fetches the daily habits (with completion status) for a given date string
/// formatted as 'YYYY-MM-DD'.
final dailyHabitsProvider = FutureProvider.autoDispose
    .family<List<DailyHabitModel>, String>((ref, date) async {
  final repository = ref.watch(habitRepositoryProvider);
  final result = await repository.fetchDailyHabits(date);
  if (result['success'] == true) {
    return result['data'] as List<DailyHabitModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load daily habits');
});

/// Fetches streak data for all habits belonging to the current user.
final habitStreaksProvider =
    FutureProvider.autoDispose<List<HabitStreakModel>>((ref) async {
  final repository = ref.watch(habitRepositoryProvider);
  final result = await repository.fetchStreaks();
  if (result['success'] == true) {
    return result['data'] as List<HabitStreakModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load streaks');
});

/// Fetches all habit definitions (used on the trainer manager screen).
final habitsProvider =
    FutureProvider.autoDispose<List<HabitModel>>((ref) async {
  final repository = ref.watch(habitRepositoryProvider);
  final result = await repository.fetchHabits();
  if (result['success'] == true) {
    return result['data'] as List<HabitModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load habits');
});

/// Notifier that handles toggling a habit's completion and invalidating
/// dependent providers so the UI refreshes.
class ToggleHabitNotifier extends StateNotifier<AsyncValue<void>> {
  final HabitRepository _repository;
  final Ref _ref;

  ToggleHabitNotifier(this._repository, this._ref)
      : super(const AsyncData(null));

  Future<bool> toggle({
    required int habitId,
    required String date,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.toggleHabit(
      habitId: habitId,
      date: date,
    );
    if (result['success'] == true) {
      state = const AsyncData(null);
      // Invalidate daily habits so the checklist refreshes.
      _ref.invalidate(dailyHabitsProvider);
      // Invalidate streaks so the badge updates.
      _ref.invalidate(habitStreaksProvider);
      return true;
    }
    final error = result['error'] ?? 'Failed to toggle habit';
    state = AsyncError(error, StackTrace.current);
    return false;
  }
}

/// Provider for the [ToggleHabitNotifier].
final toggleHabitProvider =
    StateNotifierProvider.autoDispose<ToggleHabitNotifier, AsyncValue<void>>(
  (ref) {
    final repository = ref.watch(habitRepositoryProvider);
    return ToggleHabitNotifier(repository, ref);
  },
);
