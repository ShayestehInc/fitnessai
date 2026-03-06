import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../data/models/nutrition_models.dart';
import '../../data/repositories/meal_log_repository.dart';

// Repository provider
final mealLogRepositoryProvider = Provider<MealLogRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MealLogRepository(apiClient);
});

// State
class MealLogState {
  final List<MealLogModel> meals;
  final MealLogSummaryModel? summary;
  final String? activeFatMode;
  final bool isLoading;
  final String? error;

  const MealLogState({
    this.meals = const [],
    this.summary,
    this.activeFatMode,
    this.isLoading = false,
    this.error,
  });

  MealLogState copyWith({
    List<MealLogModel>? meals,
    MealLogSummaryModel? summary,
    String? activeFatMode,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MealLogState(
      meals: meals ?? this.meals,
      summary: summary ?? this.summary,
      activeFatMode: activeFatMode ?? this.activeFatMode,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Notifier
class MealLogNotifier extends StateNotifier<MealLogState> {
  final MealLogRepository _repository;

  MealLogNotifier(this._repository) : super(const MealLogState());

  /// Load meals and summary for a given date.
  Future<void> loadForDate(String date) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final results = await Future.wait([
      _repository.getMeals(date),
      _repository.getSummary(date),
      _repository.getActiveAssignment(),
    ]);

    final mealsResult = results[0];
    final summaryResult = results[1];
    final assignmentResult = results[2];

    List<MealLogModel> meals = [];
    MealLogSummaryModel? summary;
    String? fatMode;

    if (mealsResult['success'] == true) {
      meals = mealsResult['meals'] as List<MealLogModel>;
    }
    if (summaryResult['success'] == true) {
      summary = summaryResult['summary'] as MealLogSummaryModel;
    }
    if (assignmentResult['success'] == true) {
      final data = assignmentResult['data'] as Map<String, dynamic>;
      fatMode = data['fat_mode'] as String?;
    }

    state = state.copyWith(
      meals: meals,
      summary: summary,
      activeFatMode: fatMode,
      isLoading: false,
      error: mealsResult['success'] != true ? mealsResult['error'] as String? : null,
    );
  }

  /// Quick-add a food entry.
  Future<bool> quickAdd({
    required String date,
    required int mealNumber,
    String mealName = '',
    int? foodItemId,
    String customName = '',
    double quantity = 1.0,
    String servingUnit = 'serving',
    int calories = 0,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
  }) async {
    final result = await _repository.quickAdd(
      date: date,
      mealNumber: mealNumber,
      mealName: mealName,
      foodItemId: foodItemId,
      customName: customName,
      quantity: quantity,
      servingUnit: servingUnit,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fatMode: state.activeFatMode ?? 'total_fat',
    );

    if (result['success'] == true) {
      // Reload data for the date
      await loadForDate(date);
      return true;
    }

    state = state.copyWith(error: result['error'] as String?);
    return false;
  }

  /// Delete a single entry (optimistic).
  Future<bool> deleteEntry(int entryId, String date) async {
    // Optimistic: remove entry from local state
    final previousMeals = state.meals;
    final updatedMeals = state.meals.map((meal) {
      final filtered = meal.entries.where((e) => e.id != entryId).toList();
      if (filtered.length == meal.entries.length) return meal;
      return meal.copyWith(entries: filtered);
    }).toList();
    state = state.copyWith(meals: updatedMeals);

    final result = await _repository.deleteEntry(entryId);
    if (result['success'] == true) {
      // Reload summary
      final summaryResult = await _repository.getSummary(date);
      if (summaryResult['success'] == true) {
        state = state.copyWith(
          summary: summaryResult['summary'] as MealLogSummaryModel,
        );
      }
      return true;
    }

    // Rollback on failure
    state = state.copyWith(
      meals: previousMeals,
      error: result['error'] as String?,
    );
    return false;
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final mealLogProvider =
    StateNotifierProvider<MealLogNotifier, MealLogState>((ref) {
  final repository = ref.watch(mealLogRepositoryProvider);
  return MealLogNotifier(repository);
});
