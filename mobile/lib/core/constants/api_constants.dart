class ApiConstants {
  // Base URL - Update this to your Django backend URL
  static const String baseUrl = 'http://localhost:8000';
  static const String apiBaseUrl = '$baseUrl/api';

  // Auth endpoints
  static const String login = '$apiBaseUrl/auth/jwt/create/';
  static const String register = '$apiBaseUrl/auth/users/';
  static const String refreshToken = '$apiBaseUrl/auth/jwt/refresh/';
  static const String currentUser = '$apiBaseUrl/auth/users/me/';

  // User profile endpoints
  static const String profiles = '$apiBaseUrl/users/profiles/';
  static const String onboardingStep = '$apiBaseUrl/users/profiles/onboarding/';
  static const String completeOnboarding = '$apiBaseUrl/users/profiles/complete-onboarding/';
  static const String deleteAccount = '$apiBaseUrl/users/profiles/delete-account/';

  // Workout endpoints
  static const String parseNaturalLanguage = '$apiBaseUrl/workouts/daily-logs/parse-natural-language/';
  static const String confirmAndSaveLog = '$apiBaseUrl/workouts/daily-logs/confirm-and-save/';
  static const String dailyLogs = '$apiBaseUrl/workouts/daily-logs/';
  static const String nutritionSummary = '$apiBaseUrl/workouts/daily-logs/nutrition-summary/';
  static const String workoutSummary = '$apiBaseUrl/workouts/daily-logs/workout-summary/';
  static const String programs = '$apiBaseUrl/workouts/programs/';
  static const String exercises = '$apiBaseUrl/workouts/exercises/';

  // Nutrition endpoints
  static const String nutritionGoals = '$apiBaseUrl/workouts/nutrition-goals/';
  static const String trainerAdjustGoals = '$apiBaseUrl/workouts/nutrition-goals/trainer-adjust/';
  static const String weightCheckIns = '$apiBaseUrl/workouts/weight-checkins/';
  static const String latestWeightCheckIn = '$apiBaseUrl/workouts/weight-checkins/latest/';

  // Trainer endpoints
  static const String trainerDashboard = '$apiBaseUrl/trainer/dashboard/';
  static const String trainerStats = '$apiBaseUrl/trainer/dashboard/stats/';
  static const String trainerTrainees = '$apiBaseUrl/trainer/trainees/';
  static const String trainerInvitations = '$apiBaseUrl/trainer/invitations/';
  static const String startImpersonation = '$apiBaseUrl/trainer/impersonate/';
  static const String endImpersonation = '$apiBaseUrl/trainer/impersonate/end/';
  static const String programTemplates = '$apiBaseUrl/trainer/program-templates/';
  static const String trainerAnalyticsAdherence = '$apiBaseUrl/trainer/analytics/adherence/';
  static const String trainerAnalyticsProgress = '$apiBaseUrl/trainer/analytics/progress/';

  // Feature request endpoints
  static const String featureRequests = '$apiBaseUrl/features/';

  // Headers
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}
