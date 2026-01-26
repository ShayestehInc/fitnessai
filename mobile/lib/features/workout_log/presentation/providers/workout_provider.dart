import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/workout_models.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkoutRepository(apiClient);
});

final workoutStateProvider =
    StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return WorkoutNotifier(repository);
});

class WorkoutState {
  final DateTime selectedDate;
  final WorkoutSummary? dailySummary;
  final ProgramModel? activeProgram;
  final List<ProgramModel> programs;
  final bool isLoading;
  final String? error;

  WorkoutState({
    DateTime? selectedDate,
    this.dailySummary,
    this.activeProgram,
    this.programs = const [],
    this.isLoading = false,
    this.error,
  }) : selectedDate = selectedDate ?? DateTime.now();

  WorkoutState copyWith({
    DateTime? selectedDate,
    WorkoutSummary? dailySummary,
    ProgramModel? activeProgram,
    List<ProgramModel>? programs,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutState(
      selectedDate: selectedDate ?? this.selectedDate,
      dailySummary: dailySummary ?? this.dailySummary,
      activeProgram: activeProgram ?? this.activeProgram,
      programs: programs ?? this.programs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (selected == today) {
      return 'Today';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (selected == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d, yyyy').format(selectedDate);
    }
  }

  String get dateParam => DateFormat('yyyy-MM-dd').format(selectedDate);
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final WorkoutRepository _repository;

  WorkoutNotifier(this._repository) : super(WorkoutState());

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);

    // Load workout summary and programs in parallel
    final results = await Future.wait([
      _repository.getDailyWorkoutSummary(state.dateParam),
      _repository.getPrograms(),
    ]);

    final summaryResult = results[0];
    final programsResult = results[1];

    ProgramModel? activeProgram;
    List<ProgramModel> programs = [];

    if (programsResult['success'] == true) {
      programs = programsResult['programs'] as List<ProgramModel>;
      activeProgram = programs.isNotEmpty
          ? programs.firstWhere(
              (p) => p.isActive,
              orElse: () => programs.first,
            )
          : null;
    }

    state = state.copyWith(
      isLoading: false,
      dailySummary: summaryResult['success'] == true
          ? summaryResult['summary'] as WorkoutSummary
          : null,
      programs: programs,
      activeProgram: activeProgram,
    );
  }

  Future<void> refreshDailySummary() async {
    state = state.copyWith(isLoading: true, error: null);

    final result =
        await _repository.getDailyWorkoutSummary(state.dateParam);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        dailySummary: result['summary'] as WorkoutSummary,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    refreshDailySummary();
  }

  void goToPreviousDay() {
    selectDate(state.selectedDate.subtract(const Duration(days: 1)));
  }

  void goToNextDay() {
    selectDate(state.selectedDate.add(const Duration(days: 1)));
  }

  void goToToday() {
    selectDate(DateTime.now());
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
