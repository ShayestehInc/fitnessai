import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/data/models/user_profile_model.dart';
import '../../../onboarding/data/repositories/onboarding_repository.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/models/nutrition_models.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NutritionRepository(apiClient);
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingRepository(apiClient);
});

final nutritionStateProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  final nutritionRepo = ref.watch(nutritionRepositoryProvider);
  final onboardingRepo = ref.watch(onboardingRepositoryProvider);
  final db = ref.watch(databaseProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  return NutritionNotifier(nutritionRepo, onboardingRepo, db, userId);
});

class NutritionState {
  final DateTime selectedDate;
  final NutritionGoalModel? goals;
  final DailyNutritionSummary? dailySummary;
  final WeightCheckInModel? latestCheckIn;
  final List<WeightCheckInModel> weightHistory;
  final List<MacroPresetModel> macroPresets;
  final MacroPresetModel? activePreset;
  final UserProfileModel? userProfile;
  final int pendingNutritionCount;
  final int pendingCalories;
  final int pendingProtein;
  final int pendingCarbs;
  final int pendingFat;
  final List<PendingWeightDisplay> pendingWeights;
  final bool isLoading;
  final String? error;

  NutritionState({
    DateTime? selectedDate,
    this.goals,
    this.dailySummary,
    this.latestCheckIn,
    this.weightHistory = const [],
    this.macroPresets = const [],
    this.activePreset,
    this.userProfile,
    this.pendingNutritionCount = 0,
    this.pendingCalories = 0,
    this.pendingProtein = 0,
    this.pendingCarbs = 0,
    this.pendingFat = 0,
    this.pendingWeights = const [],
    this.isLoading = false,
    this.error,
  }) : selectedDate = selectedDate ?? DateTime.now();

  NutritionState copyWith({
    DateTime? selectedDate,
    NutritionGoalModel? goals,
    DailyNutritionSummary? dailySummary,
    WeightCheckInModel? latestCheckIn,
    List<WeightCheckInModel>? weightHistory,
    List<MacroPresetModel>? macroPresets,
    MacroPresetModel? activePreset,
    UserProfileModel? userProfile,
    int? pendingNutritionCount,
    int? pendingCalories,
    int? pendingProtein,
    int? pendingCarbs,
    int? pendingFat,
    List<PendingWeightDisplay>? pendingWeights,
    bool? isLoading,
    String? error,
  }) {
    return NutritionState(
      selectedDate: selectedDate ?? this.selectedDate,
      goals: goals ?? this.goals,
      dailySummary: dailySummary ?? this.dailySummary,
      latestCheckIn: latestCheckIn ?? this.latestCheckIn,
      weightHistory: weightHistory ?? this.weightHistory,
      macroPresets: macroPresets ?? this.macroPresets,
      activePreset: activePreset ?? this.activePreset,
      userProfile: userProfile ?? this.userProfile,
      pendingNutritionCount:
          pendingNutritionCount ?? this.pendingNutritionCount,
      pendingCalories: pendingCalories ?? this.pendingCalories,
      pendingProtein: pendingProtein ?? this.pendingProtein,
      pendingCarbs: pendingCarbs ?? this.pendingCarbs,
      pendingFat: pendingFat ?? this.pendingFat,
      pendingWeights: pendingWeights ?? this.pendingWeights,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check if trainee has any macro presets from trainer
  bool get hasPresets => macroPresets.isNotEmpty;

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

  /// Get the user's goal label (e.g., "Fat Loss", "Build Muscle")
  String get goalLabel {
    final goal = userProfile?.goal ?? 'build_muscle';
    return ProfileEnums.goalLabels[goal] ?? 'Build Muscle';
  }

  /// Get formatted latest weight (in lbs)
  String get latestWeightFormatted {
    if (latestCheckIn == null) return '--';
    final lbs = latestCheckIn!.weightKg * 2.20462;
    return '${lbs.round()} lbs';
  }

  /// Get formatted latest weight date
  String get latestWeightDate {
    if (latestCheckIn == null) return '';
    try {
      final date = DateTime.parse(latestCheckIn!.date);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return latestCheckIn!.date;
    }
  }

  // Calculated values
  int get caloriesRemaining => dailySummary?.remaining.calories ?? goals?.caloriesGoal ?? 0;
  int get proteinRemaining => dailySummary?.remaining.protein ?? goals?.proteinGoal ?? 0;
  int get carbsRemaining => dailySummary?.remaining.carbs ?? goals?.carbsGoal ?? 0;
  int get fatRemaining => dailySummary?.remaining.fat ?? goals?.fatGoal ?? 0;

  int get proteinConsumed => dailySummary?.consumed.protein ?? 0;
  int get carbsConsumed => dailySummary?.consumed.carbs ?? 0;
  int get fatConsumed => dailySummary?.consumed.fat ?? 0;

  int get proteinGoal => goals?.proteinGoal ?? 0;
  int get carbsGoal => goals?.carbsGoal ?? 0;
  int get fatGoal => goals?.fatGoal ?? 0;

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

/// Display data for a pending (offline) weight check-in.
class PendingWeightDisplay {
  final String clientId;
  final String date;
  final double weightKg;
  final String notes;

  const PendingWeightDisplay({
    required this.clientId,
    required this.date,
    required this.weightKg,
    required this.notes,
  });
}

class NutritionNotifier extends StateNotifier<NutritionState> {
  final NutritionRepository _nutritionRepo;
  final OnboardingRepository _onboardingRepo;
  final AppDatabase _db;
  final int? _userId;

  NutritionNotifier(
    this._nutritionRepo,
    this._onboardingRepo,
    this._db,
    this._userId,
  ) : super(NutritionState());

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);

    // Load goals, daily summary, latest check-in, user profile, and presets in parallel
    final results = await Future.wait([
      _nutritionRepo.getNutritionGoals(),
      _nutritionRepo.getDailyNutritionSummary(state.dateParam),
      _nutritionRepo.getLatestWeightCheckIn(),
      _onboardingRepo.getProfile(),
      _nutritionRepo.getMacroPresets(),
    ]);

    final goalsResult = results[0];
    final summaryResult = results[1];
    final checkInResult = results[2];
    final profileResult = results[3];
    final presetsResult = results[4];

    List<MacroPresetModel> presets = [];
    MacroPresetModel? defaultPreset;
    if (presetsResult['success'] == true) {
      presets = presetsResult['presets'] as List<MacroPresetModel>;
      // Find the default preset if any
      defaultPreset = presets.cast<MacroPresetModel?>().firstWhere(
        (p) => p!.isDefault,
        orElse: () => null,
      );
    }

    // Load pending nutrition and weight data from local DB
    final pendingNutrition = await _loadPendingNutrition(state.dateParam);
    final pendingWeightList = await _loadPendingWeights();

    // Find effective latest check-in (server or pending, whichever is more recent)
    WeightCheckInModel? effectiveLatestCheckIn;
    if (checkInResult['success'] == true) {
      effectiveLatestCheckIn = checkInResult['checkIn'] as WeightCheckInModel;
    }
    if (pendingWeightList.isNotEmpty) {
      final latestPending = pendingWeightList.first;
      if (effectiveLatestCheckIn == null ||
          latestPending.date.compareTo(effectiveLatestCheckIn.date) > 0) {
        // Pending weight is more recent -- use it for display
        effectiveLatestCheckIn = WeightCheckInModel(
          date: latestPending.date,
          weightKg: latestPending.weightKg,
          notes: latestPending.notes,
        );
      }
    }

    state = state.copyWith(
      isLoading: false,
      goals: goalsResult['success'] == true
          ? goalsResult['goals'] as NutritionGoalModel
          : null,
      dailySummary: summaryResult['success'] == true
          ? summaryResult['summary'] as DailyNutritionSummary
          : null,
      latestCheckIn: effectiveLatestCheckIn,
      userProfile: profileResult['success'] == true
          ? profileResult['profile'] as UserProfileModel
          : null,
      macroPresets: presets,
      activePreset: defaultPreset,
      pendingNutritionCount: pendingNutrition.count,
      pendingCalories: pendingNutrition.calories,
      pendingProtein: pendingNutrition.protein,
      pendingCarbs: pendingNutrition.carbs,
      pendingFat: pendingNutrition.fat,
      pendingWeights: pendingWeightList,
    );
  }

  Future<void> loadWeightHistory() async {
    final results = await Future.wait([
      _nutritionRepo.getWeightCheckInHistory(),
      _loadPendingWeights(),
    ]);

    final historyResult = results[0] as Map<String, dynamic>;
    final pendingWeightList = results[1] as List<PendingWeightDisplay>;

    if (historyResult['success'] == true) {
      state = state.copyWith(
        weightHistory: historyResult['checkIns'] as List<WeightCheckInModel>,
        pendingWeights: pendingWeightList,
      );
    } else {
      // Even if server history fails, update pending weights
      state = state.copyWith(pendingWeights: pendingWeightList);
    }
  }

  Future<void> refreshDailySummary() async {
    state = state.copyWith(isLoading: true, error: null);

    final results = await Future.wait([
      _nutritionRepo.getDailyNutritionSummary(state.dateParam),
      _loadPendingNutrition(state.dateParam),
    ]);

    final summaryResult = results[0] as Map<String, dynamic>;
    final pendingNutrition = results[1] as _PendingNutritionResult;

    if (summaryResult['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        dailySummary: summaryResult['summary'] as DailyNutritionSummary,
        pendingNutritionCount: pendingNutrition.count,
        pendingCalories: pendingNutrition.calories,
        pendingProtein: pendingNutrition.protein,
        pendingCarbs: pendingNutrition.carbs,
        pendingFat: pendingNutrition.fat,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: summaryResult['error'] as String?,
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

    final result = await _nutritionRepo.createWeightCheckIn(
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

  /// Load pending nutrition entries from local DB for the given date.
  /// Sums macros across all pending entries.
  Future<_PendingNutritionResult> _loadPendingNutrition(String date) async {
    final userId = _userId;
    if (userId == null) return const _PendingNutritionResult.empty();

    try {
      final pendingRows =
          await _db.nutritionCacheDao.getPendingNutritionForUser(userId, date);
      if (pendingRows.isEmpty) return const _PendingNutritionResult.empty();

      int totalCalories = 0;
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFat = 0;

      for (final row in pendingRows) {
        try {
          final parsedData =
              jsonDecode(row.parsedDataJson) as Map<String, dynamic>;
          // The parsed_data contains the food data from the AI parser
          // Structure: {"foods": [{"protein": X, "carbs": Y, ...}]}
          // or it might be a flat map with totals
          final foods = parsedData['foods'] as List?;
          if (foods != null) {
            for (final food in foods) {
              if (food is Map<String, dynamic>) {
                totalProtein += (food['protein'] as num?)?.toInt() ?? 0;
                totalCarbs += (food['carbs'] as num?)?.toInt() ?? 0;
                totalFat += (food['fat'] as num?)?.toInt() ?? 0;
                totalCalories += (food['calories'] as num?)?.toInt() ?? 0;
              }
            }
          } else {
            // Flat structure
            totalProtein += (parsedData['protein'] as num?)?.toInt() ?? 0;
            totalCarbs += (parsedData['carbs'] as num?)?.toInt() ?? 0;
            totalFat += (parsedData['fat'] as num?)?.toInt() ?? 0;
            totalCalories += (parsedData['calories'] as num?)?.toInt() ?? 0;
          }
        } catch (_) {
          // Corrupted JSON -- skip this entry's macros
        }
      }

      return _PendingNutritionResult(
        count: pendingRows.length,
        calories: totalCalories,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
      );
    } catch (e) {
      assert(() {
        debugPrint('Failed to load pending nutrition: $e');
        return true;
      }());
      return const _PendingNutritionResult.empty();
    }
  }

  /// Load pending weight check-ins from local DB.
  Future<List<PendingWeightDisplay>> _loadPendingWeights() async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      final pendingRows =
          await _db.nutritionCacheDao.getPendingWeightForUser(userId);
      return pendingRows.map((row) {
        return PendingWeightDisplay(
          clientId: row.clientId,
          date: row.date,
          weightKg: row.weightKg,
          notes: row.notes,
        );
      }).toList();
    } catch (e) {
      assert(() {
        debugPrint('Failed to load pending weights: $e');
        return true;
      }());
      return [];
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Apply a macro preset to update today's goals
  Future<bool> applyPreset(MacroPresetModel preset) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _nutritionRepo.applyMacroPreset(preset.id);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        goals: result['goals'] as NutritionGoalModel,
        activePreset: preset,
      );
      // Refresh the daily summary with new goals
      await refreshDailySummary();
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  /// Set active preset without applying (just for display)
  void setActivePreset(MacroPresetModel? preset) {
    state = state.copyWith(activePreset: preset);
  }

  /// Get the daily log ID for a given date by fetching the daily logs list
  Future<int?> getDailyLogId(String date) async {
    try {
      final response = await _nutritionRepo.getDailyLogForDate(date);
      if (response['success'] == true) {
        return response['logId'] as int?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Internal result class for pending nutrition macro totals.
class _PendingNutritionResult {
  final int count;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const _PendingNutritionResult({
    required this.count,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  const _PendingNutritionResult.empty()
      : count = 0,
        calories = 0,
        protein = 0,
        carbs = 0,
        fat = 0;
}
