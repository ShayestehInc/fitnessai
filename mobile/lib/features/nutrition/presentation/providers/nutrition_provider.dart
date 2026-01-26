import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/models/nutrition_models.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NutritionRepository(apiClient);
});

final nutritionStateProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  final repository = ref.watch(nutritionRepositoryProvider);
  return NutritionNotifier(repository);
});

class NutritionState {
  final DateTime selectedDate;
  final NutritionGoalModel? goals;
  final DailyNutritionSummary? dailySummary;
  final WeightCheckInModel? latestCheckIn;
  final bool isLoading;
  final String? error;

  NutritionState({
    DateTime? selectedDate,
    this.goals,
    this.dailySummary,
    this.latestCheckIn,
    this.isLoading = false,
    this.error,
  }) : selectedDate = selectedDate ?? DateTime.now();

  NutritionState copyWith({
    DateTime? selectedDate,
    NutritionGoalModel? goals,
    DailyNutritionSummary? dailySummary,
    WeightCheckInModel? latestCheckIn,
    bool? isLoading,
    String? error,
  }) {
    return NutritionState(
      selectedDate: selectedDate ?? this.selectedDate,
      goals: goals ?? this.goals,
      dailySummary: dailySummary ?? this.dailySummary,
      latestCheckIn: latestCheckIn ?? this.latestCheckIn,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

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

  // Calculated values
  int get caloriesRemaining => dailySummary?.remaining.calories ?? goals?.caloriesGoal ?? 0;
  int get proteinRemaining => dailySummary?.remaining.protein ?? goals?.proteinGoal ?? 0;
  int get carbsRemaining => dailySummary?.remaining.carbs ?? goals?.carbsGoal ?? 0;
  int get fatRemaining => dailySummary?.remaining.fat ?? goals?.fatGoal ?? 0;

  double get proteinProgress {
    final goal = goals?.proteinGoal ?? 0;
    if (goal == 0) return 0;
    return (dailySummary?.consumed.protein ?? 0) / goal;
  }

  double get carbsProgress {
    final goal = goals?.carbsGoal ?? 0;
    if (goal == 0) return 0;
    return (dailySummary?.consumed.carbs ?? 0) / goal;
  }

  double get fatProgress {
    final goal = goals?.fatGoal ?? 0;
    if (goal == 0) return 0;
    return (dailySummary?.consumed.fat ?? 0) / goal;
  }

  double get caloriesProgress {
    final goal = goals?.caloriesGoal ?? 0;
    if (goal == 0) return 0;
    return (dailySummary?.consumed.calories ?? 0) / goal;
  }
}

class NutritionNotifier extends StateNotifier<NutritionState> {
  final NutritionRepository _repository;

  NutritionNotifier(this._repository) : super(NutritionState());

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);

    // Load goals, daily summary, and latest check-in in parallel
    final results = await Future.wait([
      _repository.getNutritionGoals(),
      _repository.getDailyNutritionSummary(state.dateParam),
      _repository.getLatestWeightCheckIn(),
    ]);

    final goalsResult = results[0];
    final summaryResult = results[1];
    final checkInResult = results[2];

    state = state.copyWith(
      isLoading: false,
      goals: goalsResult['success'] == true
          ? goalsResult['goals'] as NutritionGoalModel
          : null,
      dailySummary: summaryResult['success'] == true
          ? summaryResult['summary'] as DailyNutritionSummary
          : null,
      latestCheckIn: checkInResult['success'] == true
          ? checkInResult['checkIn'] as WeightCheckInModel
          : null,
    );
  }

  Future<void> refreshDailySummary() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getDailyNutritionSummary(state.dateParam);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        dailySummary: result['summary'] as DailyNutritionSummary,
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

  Future<bool> createWeightCheckIn({
    required double weightKg,
    String notes = '',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createWeightCheckIn(
      date: state.dateParam,
      weightKg: weightKg,
      notes: notes,
    );

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        latestCheckIn: result['checkIn'] as WeightCheckInModel,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
