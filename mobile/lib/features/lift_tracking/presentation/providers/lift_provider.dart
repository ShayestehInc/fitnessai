import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/lift_models.dart';
import '../../data/repositories/lift_repository.dart';

final liftRepositoryProvider = Provider<LiftRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LiftRepository(apiClient);
});

/// State for the lift tracking feature.
class LiftState {
  final List<LiftMaxModel> liftMaxes;
  final Map<String, dynamic>? selectedExerciseHistory;
  final WorkloadWeeklyModel? weeklyWorkload;
  final WorkloadTrendsModel? workloadTrends;
  final bool isLoading;
  final String? error;

  const LiftState({
    this.liftMaxes = const [],
    this.selectedExerciseHistory,
    this.weeklyWorkload,
    this.workloadTrends,
    this.isLoading = false,
    this.error,
  });

  LiftState copyWith({
    List<LiftMaxModel>? liftMaxes,
    Map<String, dynamic>? selectedExerciseHistory,
    bool clearSelectedExerciseHistory = false,
    WorkloadWeeklyModel? weeklyWorkload,
    WorkloadTrendsModel? workloadTrends,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LiftState(
      liftMaxes: liftMaxes ?? this.liftMaxes,
      selectedExerciseHistory: clearSelectedExerciseHistory
          ? null
          : (selectedExerciseHistory ?? this.selectedExerciseHistory),
      weeklyWorkload: weeklyWorkload ?? this.weeklyWorkload,
      workloadTrends: workloadTrends ?? this.workloadTrends,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LiftNotifier extends StateNotifier<LiftState> {
  final LiftRepository _repository;

  LiftNotifier(this._repository) : super(const LiftState());

  Future<void> loadLiftMaxes({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getLiftMaxes(page: page);
    if (result['success'] == true) {
      state = state.copyWith(
        liftMaxes: result['data'] as List<LiftMaxModel>,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<void> loadExerciseHistory(int exerciseId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getLiftMaxHistory(exerciseId);
    if (result['success'] == true) {
      state = state.copyWith(
        selectedExerciseHistory: result['data'] as Map<String, dynamic>,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<void> loadWeeklyWorkload({String? weekStart, int? traineeId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getWeeklyWorkload(
      weekStart: weekStart,
      traineeId: traineeId,
    );
    if (result['success'] == true) {
      state = state.copyWith(
        weeklyWorkload: result['data'] as WorkloadWeeklyModel,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<void> loadWorkloadTrends({
    int weeksBack = 8,
    int? traineeId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getWorkloadTrends(
      weeksBack: weeksBack,
      traineeId: traineeId,
    );
    if (result['success'] == true) {
      state = state.copyWith(
        workloadTrends: result['data'] as WorkloadTrendsModel,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  void clearExerciseHistory() {
    state = state.copyWith(clearSelectedExerciseHistory: true);
  }
}

final liftNotifierProvider =
    StateNotifierProvider<LiftNotifier, LiftState>((ref) {
  final repository = ref.watch(liftRepositoryProvider);
  return LiftNotifier(repository);
});

/// Fetches lift set logs for a specific exercise with optional date filters.
final liftSetLogsProvider = FutureProvider.autoDispose
    .family<List<LiftSetLogModel>, LiftSetLogsParams>((ref, params) async {
  final repository = ref.watch(liftRepositoryProvider);
  final result = await repository.getLiftSetLogs(
    exerciseId: params.exerciseId,
    dateFrom: params.dateFrom,
    dateTo: params.dateTo,
    page: params.page,
  );
  if (result['success'] == true) {
    return result['data'] as List<LiftSetLogModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load lift set logs');
});

/// Parameters for the lift set logs provider.
class LiftSetLogsParams {
  final int exerciseId;
  final String? dateFrom;
  final String? dateTo;
  final int page;

  const LiftSetLogsParams({
    required this.exerciseId,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiftSetLogsParams &&
        other.exerciseId == exerciseId &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(exerciseId, dateFrom, dateTo, page);
}
