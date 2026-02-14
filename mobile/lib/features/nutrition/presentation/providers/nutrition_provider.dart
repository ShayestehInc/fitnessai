import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  return NutritionNotifier(nutritionRepo, onboardingRepo);
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

class NutritionNotifier extends StateNotifier<NutritionState> {
  final NutritionRepository _nutritionRepo;
  final OnboardingRepository _onboardingRepo;

  NutritionNotifier(this._nutritionRepo, this._onboardingRepo) : super(NutritionState());

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
      userProfile: profileResult['success'] == true
          ? profileResult['profile'] as UserProfileModel
          : null,
      macroPresets: presets,
      activePreset: defaultPreset,
    );
  }

  Future<void> loadWeightHistory() async {
    final result = await _nutritionRepo.getWeightCheckInHistory();
    if (result['success'] == true) {
      state = state.copyWith(
        weightHistory: result['checkIns'] as List<WeightCheckInModel>,
      );
    }
  }

  Future<void> refreshDailySummary() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _nutritionRepo.getDailyNutritionSummary(state.dateParam);

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
