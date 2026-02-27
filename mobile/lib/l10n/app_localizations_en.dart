// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FitnessAI';

  @override
  String get authLoginTitle => 'Welcome Back';

  @override
  String get authLoginSubtitle => 'Sign in to your account';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authLoginButton => 'Sign In';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authRegisterTitle => 'Create Account';

  @override
  String get authRegisterSubtitle => 'Join FitnessAI today';

  @override
  String get authFirstNameLabel => 'First Name';

  @override
  String get authLastNameLabel => 'Last Name';

  @override
  String get authConfirmPasswordLabel => 'Confirm Password';

  @override
  String get authConfirmPasswordHint => 'Re-enter your password';

  @override
  String get authRegisterButton => 'Create Account';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authForgotTitle => 'Reset Password';

  @override
  String get authForgotSubtitle => 'Enter your email to receive a reset link';

  @override
  String get authSendResetLink => 'Send Reset Link';

  @override
  String get authResetSent => 'Reset link sent to your email';

  @override
  String get authBackToLogin => 'Back to Login';

  @override
  String get authOrContinueWith => 'Or continue with';

  @override
  String get authGoogle => 'Google';

  @override
  String get authApple => 'Apple';

  @override
  String get authLoginFailed => 'Login failed. Please check your credentials.';

  @override
  String get authRegisterFailed => 'Registration failed. Please try again.';

  @override
  String get authInvalidEmail => 'Please enter a valid email';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get onboardingAboutYou => 'About You';

  @override
  String get onboardingActivityLevel => 'Activity Level';

  @override
  String get onboardingGoals => 'Your Goals';

  @override
  String get onboardingDiet => 'Diet Preferences';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingFinish => 'Finish Setup';

  @override
  String get onboardingSexLabel => 'Sex';

  @override
  String get onboardingSexMale => 'Male';

  @override
  String get onboardingSexFemale => 'Female';

  @override
  String get onboardingAgeLabel => 'Age';

  @override
  String get onboardingHeightLabel => 'Height (cm)';

  @override
  String get onboardingWeightLabel => 'Weight (kg)';

  @override
  String get onboardingSedentary => 'Sedentary';

  @override
  String get onboardingSedentaryDesc => 'Little or no exercise';

  @override
  String get onboardingLightlyActive => 'Lightly Active';

  @override
  String get onboardingLightlyActiveDesc => 'Light exercise 1-3 days/week';

  @override
  String get onboardingModeratelyActive => 'Moderately Active';

  @override
  String get onboardingModeratelyActiveDesc =>
      'Moderate exercise 3-5 days/week';

  @override
  String get onboardingVeryActive => 'Very Active';

  @override
  String get onboardingVeryActiveDesc => 'Hard exercise 6-7 days/week';

  @override
  String get onboardingExtremelyActive => 'Extremely Active';

  @override
  String get onboardingExtremelyActiveDesc =>
      'Very hard exercise & physical job';

  @override
  String get onboardingBuildMuscle => 'Build Muscle';

  @override
  String get onboardingBuildMuscleDesc => 'Gain lean muscle mass';

  @override
  String get onboardingFatLoss => 'Fat Loss';

  @override
  String get onboardingFatLossDesc => 'Reduce body fat percentage';

  @override
  String get onboardingRecomp => 'Body Recomp';

  @override
  String get onboardingRecompDesc => 'Build muscle while losing fat';

  @override
  String get onboardingLowCarb => 'Low Carb';

  @override
  String get onboardingBalanced => 'Balanced';

  @override
  String get onboardingHighCarb => 'High Carb';

  @override
  String get onboardingMealsPerDay => 'Meals Per Day';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get homeTitle => 'Home';

  @override
  String get homeGoodMorning => 'Good Morning';

  @override
  String get homeGoodAfternoon => 'Good Afternoon';

  @override
  String get homeGoodEvening => 'Good Evening';

  @override
  String get homeTodaysPlan => 'Today\'s Plan';

  @override
  String get homeQuickLog => 'Quick Log';

  @override
  String get homeRecentActivity => 'Recent Activity';

  @override
  String get homeNoActivity => 'No activity yet. Start logging!';

  @override
  String homeStreak(int count) {
    return '$count day streak';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navDiet => 'Diet';

  @override
  String get navLogbook => 'Logbook';

  @override
  String get navCommunity => 'Community';

  @override
  String get navMessages => 'Messages';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTrainees => 'Trainees';

  @override
  String get navPrograms => 'Programs';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSelect => 'Select Language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsBiometric => 'Biometric Login';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get settingsDeleteAccountWarning =>
      'This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get settingsLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsFeatureRequests => 'Feature Requests';

  @override
  String get settingsCalendar => 'Calendar Integration';

  @override
  String get settingsBranding => 'Branding';

  @override
  String get settingsExerciseBank => 'Exercise Bank';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDone => 'Done';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonFilter => 'Filter';

  @override
  String get commonAll => 'All';

  @override
  String get commonNone => 'None';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonErrorTryAgain => 'Something went wrong. Please try again.';

  @override
  String get commonNoResults => 'No results found';

  @override
  String get commonEmpty => 'Nothing here yet';

  @override
  String get commonSuccess => 'Success';

  @override
  String get commonSaved => 'Changes saved';

  @override
  String get commonDeleted => 'Deleted successfully';

  @override
  String get commonCopied => 'Copied to clipboard';

  @override
  String get commonViewAll => 'View All';

  @override
  String get commonRequired => 'This field is required';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonMore => 'More';

  @override
  String get commonLess => 'Less';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String commonDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get commonNeverActive => 'Never active';

  @override
  String get commonNoData => 'No data available';

  @override
  String get trainerDashboard => 'Trainer Dashboard';

  @override
  String get trainerTrainees => 'Trainees';

  @override
  String get trainerInviteTrainee => 'Invite Trainee';

  @override
  String get trainerNoTrainees => 'No Trainees Yet';

  @override
  String get trainerNoTraineesDesc =>
      'Invite your first trainee to get started';

  @override
  String get trainerAtRiskTrainees => 'At-Risk Trainees';

  @override
  String get trainerRetentionAnalytics => 'Retention Analytics';

  @override
  String get trainerAnnouncements => 'Announcements';

  @override
  String get trainerManageAnnouncements => 'Manage Announcements';

  @override
  String get trainerBroadcastDesc => 'Broadcast updates to all your trainees';

  @override
  String get trainerAiAssistant => 'AI Assistant';

  @override
  String get trainerPrograms => 'Programs';

  @override
  String get trainerExercises => 'Exercises';

  @override
  String get nutritionCalories => 'Calories';

  @override
  String get nutritionProtein => 'Protein';

  @override
  String get nutritionCarbs => 'Carbs';

  @override
  String get nutritionFat => 'Fat';

  @override
  String get nutritionMacros => 'Macros';

  @override
  String get nutritionGoal => 'Goal';

  @override
  String get nutritionRemaining => 'Remaining';

  @override
  String get nutritionConsumed => 'Consumed';

  @override
  String get nutritionLogFood => 'Log Food';

  @override
  String get nutritionWeightCheckIn => 'Weight Check-In';

  @override
  String get workoutStartWorkout => 'Start Workout';

  @override
  String get workoutCompleteWorkout => 'Complete Workout';

  @override
  String get workoutSets => 'Sets';

  @override
  String get workoutReps => 'Reps';

  @override
  String get workoutWeight => 'Weight';

  @override
  String get workoutRestTimer => 'Rest Timer';

  @override
  String get workoutHistory => 'Workout History';

  @override
  String get workoutNoProgram => 'No program assigned';

  @override
  String get workoutNoProgramDesc => 'Ask your trainer to assign a program';

  @override
  String get errorNetworkError => 'Network error. Check your connection.';

  @override
  String get errorSessionExpired => 'Session expired. Please log in again.';

  @override
  String get errorPermissionDenied => 'Permission denied';

  @override
  String get errorNotFound => 'Not found';

  @override
  String get errorServerError => 'Server error. Please try again later.';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languagePortuguese => 'Portuguese (Brazil)';

  @override
  String get languageChanged => 'Language changed successfully';
}
