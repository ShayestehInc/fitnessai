import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../nutrition/data/repositories/nutrition_repository.dart';
import '../../../nutrition/data/models/nutrition_models.dart';
import '../../../workout_log/data/repositories/workout_repository.dart';
import '../../../workout_log/data/models/workout_models.dart';

final homeStateProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final nutritionRepo = NutritionRepository(apiClient);
  final workoutRepo = WorkoutRepository(apiClient);
  return HomeNotifier(nutritionRepo, workoutRepo);
});

class HomeState {
  final NutritionGoalModel? nutritionGoals;
  final DailyNutritionSummary? todayNutrition;
  final ProgramModel? activeProgram;
  final bool isLoading;
  final String? error;

  HomeState({
    this.nutritionGoals,
    this.todayNutrition,
    this.activeProgram,
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    NutritionGoalModel? nutritionGoals,
    DailyNutritionSummary? todayNutrition,
    ProgramModel? activeProgram,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
      todayNutrition: todayNutrition ?? this.todayNutrition,
      activeProgram: activeProgram ?? this.activeProgram,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Computed values
  int get caloriesRemaining {
    final goal = nutritionGoals?.caloriesGoal ?? 0;
    final consumed = todayNutrition?.consumed.calories ?? 0;
    return (goal - consumed).clamp(0, goal);
  }

  int get caloriesGoal => nutritionGoals?.caloriesGoal ?? 0;
  int get caloriesConsumed => todayNutrition?.consumed.calories ?? 0;

  double get caloriesProgress {
    if (caloriesGoal == 0) return 0;
    return caloriesConsumed / caloriesGoal;
  }

  double get proteinProgress {
    final goal = nutritionGoals?.proteinGoal ?? 0;
    if (goal == 0) return 0;
    return (todayNutrition?.consumed.protein ?? 0) / goal;
  }

  double get carbsProgress {
    final goal = nutritionGoals?.carbsGoal ?? 0;
    if (goal == 0) return 0;
    return (todayNutrition?.consumed.carbs ?? 0) / goal;
  }

  double get fatProgress {
    final goal = nutritionGoals?.fatGoal ?? 0;
    if (goal == 0) return 0;
    return (todayNutrition?.consumed.fat ?? 0) / goal;
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final NutritionRepository _nutritionRepo;
  final WorkoutRepository _workoutRepo;

  HomeNotifier(this._nutritionRepo, this._workoutRepo) : super(HomeState());

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _nutritionRepo.getNutritionGoals(),
        _nutritionRepo.getDailyNutritionSummary(_todayDate()),
        _workoutRepo.getActiveProgram(),
      ]);

      final goalsResult = results[0];
      final nutritionResult = results[1];
      final programResult = results[2];

      state = state.copyWith(
        isLoading: false,
        nutritionGoals: goalsResult['success'] == true
            ? goalsResult['goals'] as NutritionGoalModel
            : null,
        todayNutrition: nutritionResult['success'] == true
            ? nutritionResult['summary'] as DailyNutritionSummary
            : null,
        activeProgram: programResult['success'] == true
            ? programResult['program'] as ProgramModel
            : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
