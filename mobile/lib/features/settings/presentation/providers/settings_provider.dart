import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/data/repositories/onboarding_repository.dart';
import '../../../onboarding/data/models/user_profile_model.dart';

final settingsStateProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final repository = OnboardingRepository(apiClient);
  return SettingsNotifier(repository);
});

class SettingsState {
  final UserProfileModel? profile;
  final bool isLoading;
  final bool useMetric;
  final String? error;

  SettingsState({
    this.profile,
    this.isLoading = false,
    this.useMetric = false,
    this.error,
  });

  SettingsState copyWith({
    UserProfileModel? profile,
    bool? isLoading,
    bool? useMetric,
    String? error,
  }) {
    return SettingsState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      useMetric: useMetric ?? this.useMetric,
      error: error,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final OnboardingRepository _repository;

  SettingsNotifier(this._repository) : super(SettingsState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getProfile();

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        profile: result['profile'] as UserProfileModel,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  void updateSex(String sex) {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: sex,
          age: state.profile!.age,
          heightCm: state.profile!.heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: state.profile!.goal,
          checkInDays: state.profile!.checkInDays,
          dietType: state.profile!.dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void updateAge(int age) {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: age,
          heightCm: state.profile!.heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: state.profile!.goal,
          checkInDays: state.profile!.checkInDays,
          dietType: state.profile!.dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void updateHeight(double heightCm) {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: state.profile!.age,
          heightCm: heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: state.profile!.goal,
          checkInDays: state.profile!.checkInDays,
          dietType: state.profile!.dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void updateWeight(double weightKg) {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: state.profile!.age,
          heightCm: state.profile!.heightCm,
          weightKg: weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: state.profile!.goal,
          checkInDays: state.profile!.checkInDays,
          dietType: state.profile!.dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void updateActivityLevel(String activityLevel) {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: state.profile!.age,
          heightCm: state.profile!.heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: activityLevel,
          goal: state.profile!.goal,
          checkInDays: state.profile!.checkInDays,
          dietType: state.profile!.dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void updateGoal(String goal) {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: state.profile!.age,
          heightCm: state.profile!.heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: goal,
          checkInDays: state.profile!.checkInDays,
          dietType: state.profile!.dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void updateDietType(String dietType) {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: state.profile!.age,
          heightCm: state.profile!.heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: state.profile!.goal,
          checkInDays: state.profile!.checkInDays,
          dietType: dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void updateMealsPerDay(int mealsPerDay) {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: state.profile!.age,
          heightCm: state.profile!.heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: state.profile!.goal,
          checkInDays: state.profile!.checkInDays,
          dietType: state.profile!.dietType,
          mealsPerDay: mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void toggleCheckInDay(String day) {
    if (state.profile != null) {
      final days = List<String>.from(state.profile!.checkInDays);
      if (days.contains(day)) {
        days.remove(day);
      } else {
        days.add(day);
      }
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: state.profile!.age,
          heightCm: state.profile!.heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: state.profile!.goal,
          checkInDays: days,
          dietType: state.profile!.dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void selectAllDays() {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: state.profile!.age,
          heightCm: state.profile!.heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: state.profile!.goal,
          checkInDays: List.from(ProfileEnums.weekDays),
          dietType: state.profile!.dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  void clearAllDays() {
    if (state.profile != null) {
      state = state.copyWith(
        profile: UserProfileModel(
          id: state.profile!.id,
          user: state.profile!.user,
          userEmail: state.profile!.userEmail,
          sex: state.profile!.sex,
          age: state.profile!.age,
          heightCm: state.profile!.heightCm,
          weightKg: state.profile!.weightKg,
          activityLevel: state.profile!.activityLevel,
          goal: state.profile!.goal,
          checkInDays: [],
          dietType: state.profile!.dietType,
          mealsPerDay: state.profile!.mealsPerDay,
          onboardingCompleted: state.profile!.onboardingCompleted,
        ),
      );
    }
  }

  bool get allDaysSelected =>
      state.profile?.checkInDays.length == ProfileEnums.weekDays.length;

  void toggleUnitSystem() {
    state = state.copyWith(useMetric: !state.useMetric);
  }

  Future<bool> saveProfile() async {
    if (state.profile == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.updateOnboardingStep({
      'sex': state.profile!.sex,
      'age': state.profile!.age,
      'height_cm': state.profile!.heightCm,
      'weight_kg': state.profile!.weightKg,
      'activity_level': state.profile!.activityLevel,
      'goal': state.profile!.goal,
      'check_in_days': state.profile!.checkInDays,
      'diet_type': state.profile!.dietType,
      'meals_per_day': state.profile!.mealsPerDay,
    });

    if (result['success'] == true) {
      // Recalculate nutrition goals
      await _repository.completeOnboarding();
      state = state.copyWith(
        isLoading: false,
        profile: result['profile'] as UserProfileModel,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }
}
