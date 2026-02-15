import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/repositories/workout_repository.dart';

/// State for the workout history screen.
class WorkoutHistoryState {
  final List<WorkoutHistorySummary> workouts;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const WorkoutHistoryState({
    this.workouts = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  WorkoutHistoryState copyWith({
    List<WorkoutHistorySummary>? workouts,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return WorkoutHistoryState(
      workouts: workouts ?? this.workouts,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WorkoutHistoryNotifier extends StateNotifier<WorkoutHistoryState> {
  final WorkoutRepository _workoutRepo;

  WorkoutHistoryNotifier(this._workoutRepo)
      : super(const WorkoutHistoryState());

  /// Load the first page of workout history.
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await _workoutRepo.getWorkoutHistory(page: 1);

      if (result['success'] == true) {
        final results = result['results'] as List<dynamic>? ?? [];
        final workouts = results
            .whereType<Map<String, dynamic>>()
            .map(WorkoutHistorySummary.fromJson)
            .toList();
        final hasNext = result['hasNext'] as bool? ?? false;

        state = state.copyWith(
          workouts: workouts,
          currentPage: 1,
          hasMore: hasNext,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['error'] as String? ?? 'Failed to load workout history',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load workout history',
      );
    }
  }

  /// Load next page of workout history (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _workoutRepo.getWorkoutHistory(page: nextPage);

      if (result['success'] == true) {
        final results = result['results'] as List<dynamic>? ?? [];
        final newWorkouts = results
            .whereType<Map<String, dynamic>>()
            .map(WorkoutHistorySummary.fromJson)
            .toList();
        final hasNext = result['hasNext'] as bool? ?? false;

        state = state.copyWith(
          workouts: [...state.workouts, ...newWorkouts],
          currentPage: nextPage,
          hasMore: hasNext,
          isLoadingMore: false,
        );
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          error: result['error'] as String? ?? 'Failed to load more',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more workouts',
      );
    }
  }

  /// Pull-to-refresh: reload from page 1.
  Future<void> refresh() async {
    // Reset state without isLoading flag so loadInitial() doesn't early-return
    state = const WorkoutHistoryState();
    await loadInitial();
  }
}

final workoutHistoryProvider =
    StateNotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final repo = WorkoutRepository(apiClient);
  return WorkoutHistoryNotifier(repo);
});
