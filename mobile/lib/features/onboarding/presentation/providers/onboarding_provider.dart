import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/models/user_profile_model.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingRepository(apiClient);
});

final onboardingStateProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return OnboardingNotifier(repository);
});

class OnboardingState {
  final int currentStep;
  final UserProfileModel? profile;
  final NutritionGoalsModel? nutritionGoals;
  final bool isLoading;
  final bool isCompleted;
  final String? error;

  // Step 1 data
  final String? firstName;
  final String? sex;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final bool useMetric;

  // Step 2 data
  final String activityLevel;

  // Step 3 data
  final String goal;

  // Step 4 data
  final List<String> checkInDays;
  final String dietType;
  final int mealsPerDay;

  OnboardingState({
    this.currentStep = 1,
    this.profile,
    this.nutritionGoals,
    this.isLoading = false,
    this.isCompleted = false,
    this.error,
    this.firstName,
    this.sex,
    this.age,
    this.heightCm,
    this.weightKg,
    this.useMetric = false,
    this.activityLevel = 'moderately_active',
    this.goal = 'build_muscle',
    this.checkInDays = const [],
    this.dietType = 'balanced',
    this.mealsPerDay = 4,
  });

  OnboardingState copyWith({
    int? currentStep,
    UserProfileModel? profile,
    NutritionGoalsModel? nutritionGoals,
    bool? isLoading,
    bool? isCompleted,
    String? error,
    String? firstName,
    String? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    bool? useMetric,
    String? activityLevel,
    String? goal,
    List<String>? checkInDays,
    String? dietType,
    int? mealsPerDay,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      profile: profile ?? this.profile,
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error,
      firstName: firstName ?? this.firstName,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      useMetric: useMetric ?? this.useMetric,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      checkInDays: checkInDays ?? this.checkInDays,
      dietType: dietType ?? this.dietType,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
    );
  }

  bool get canProceedStep1 =>
      firstName != null && firstName!.isNotEmpty && sex != null && age != null && heightCm != null && weightKg != null;
  bool get canProceedStep2 => activityLevel.isNotEmpty;
  bool get canProceedStep3 => goal.isNotEmpty;
  bool get canProceedStep4 => checkInDays.isNotEmpty && dietType.isNotEmpty;
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repository;

  OnboardingNotifier(this._repository) : super(OnboardingState());

  void setFirstName(String firstName) {
    state = state.copyWith(firstName: firstName);
  }

  void setSex(String sex) {
    state = state.copyWith(sex: sex);
  }

  void setAge(int age) {
    state = state.copyWith(age: age);
  }

  void setHeight(double heightCm) {
    state = state.copyWith(heightCm: heightCm);
  }

  void setWeight(double weightKg) {
    state = state.copyWith(weightKg: weightKg);
  }

  void toggleUnitSystem() {
    state = state.copyWith(useMetric: !state.useMetric);
  }

  void setActivityLevel(String level) {
    state = state.copyWith(activityLevel: level);
  }

  void setGoal(String goal) {
    state = state.copyWith(goal: goal);
  }

  void toggleCheckInDay(String day) {
    final days = List<String>.from(state.checkInDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    state = state.copyWith(checkInDays: days);
  }

  void selectAllDays() {
    state = state.copyWith(checkInDays: List.from(ProfileEnums.weekDays));
  }

  void clearAllDays() {
    state = state.copyWith(checkInDays: []);
  }

  bool get allDaysSelected => state.checkInDays.length == ProfileEnums.weekDays.length;

  void setDietType(String dietType) {
    state = state.copyWith(dietType: dietType);
  }

  void setMealsPerDay(int meals) {
    state = state.copyWith(mealsPerDay: meals);
  }

  Future<bool> saveStep1() async {
    if (!state.canProceedStep1) return false;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.updateOnboardingStep({
      'first_name': state.firstName,
      'sex': state.sex,
      'age': state.age,
      'height_cm': state.heightCm,
      'weight_kg': state.weightKg,
    });

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        profile: result['profile'] as UserProfileModel,
        currentStep: 2,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  Future<bool> saveStep2() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.updateOnboardingStep({
      'activity_level': state.activityLevel,
    });

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        profile: result['profile'] as UserProfileModel,
        currentStep: 3,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  Future<bool> saveStep3() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.updateOnboardingStep({
      'goal': state.goal,
    });

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        profile: result['profile'] as UserProfileModel,
        currentStep: 4,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  Future<bool> saveStep4AndComplete() async {
    if (!state.canProceedStep4) return false;

    state = state.copyWith(isLoading: true, error: null);

    // Save step 4 data
    final step4Result = await _repository.updateOnboardingStep({
      'check_in_days': state.checkInDays,
      'diet_type': state.dietType,
      'meals_per_day': state.mealsPerDay,
    });

    if (step4Result['success'] != true) {
      state = state.copyWith(
        isLoading: false,
        error: step4Result['error'] as String?,
      );
      return false;
    }

    // Complete onboarding
    final result = await _repository.completeOnboarding();

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        profile: result['profile'] as UserProfileModel,
        nutritionGoals: result['nutrition_goals'] as NutritionGoalsModel,
        isCompleted: true,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 4) {
      state = state.copyWith(currentStep: step);
    }
  }

  void goBack() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void reset() {
    state = OnboardingState();
  }
}
