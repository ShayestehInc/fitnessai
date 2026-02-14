import '../services/api_config_service.dart';

class ApiConstants {
  // Base URL - Now configurable via ApiConfigService
  static String get baseUrl => ApiConfigService.getBaseUrlSync();
  static String get apiBaseUrl => '$baseUrl/api';

  // Auth endpoints
  static String get login => '$apiBaseUrl/auth/jwt/create/';
  static String get register => '$apiBaseUrl/auth/users/';
  static String get refreshToken => '$apiBaseUrl/auth/jwt/refresh/';
  static String get currentUser => '$apiBaseUrl/auth/users/me/';

  // Social auth endpoints
  static String get googleLogin => '$apiBaseUrl/users/auth/google/';
  static String get appleLogin => '$apiBaseUrl/users/auth/apple/';

  // User profile endpoints
  static String get profiles => '$apiBaseUrl/users/profiles/';
  static String get onboardingStep => '$apiBaseUrl/users/profiles/onboarding/';
  static String get completeOnboarding => '$apiBaseUrl/users/profiles/complete-onboarding/';
  static String get deleteAccount => '$apiBaseUrl/users/profiles/delete-account/';
  static String get profileImage => '$apiBaseUrl/users/profile-image/';
  static String get userMe => '$apiBaseUrl/users/me/';

  // Workout endpoints
  static String get parseNaturalLanguage => '$apiBaseUrl/workouts/daily-logs/parse-natural-language/';
  static String get confirmAndSaveLog => '$apiBaseUrl/workouts/daily-logs/confirm-and-save/';
  static String get dailyLogs => '$apiBaseUrl/workouts/daily-logs/';
  static String get nutritionSummary => '$apiBaseUrl/workouts/daily-logs/nutrition-summary/';
  static String get workoutSummary => '$apiBaseUrl/workouts/daily-logs/workout-summary/';
  static String get programs => '$apiBaseUrl/workouts/programs/';
  static String programDetail(int id) => '$apiBaseUrl/workouts/programs/$id/';
  static String get exercises => '$apiBaseUrl/workouts/exercises/';

  // Workout survey endpoints
  static String get workoutReadinessSurvey => '$apiBaseUrl/workouts/surveys/readiness/';
  static String get workoutPostSurvey => '$apiBaseUrl/workouts/surveys/post-workout/';
  static String get myWorkoutLayout => '$apiBaseUrl/workouts/my-layout/';

  // Nutrition endpoints
  static String get nutritionGoals => '$apiBaseUrl/workouts/nutrition-goals/';
  static String get trainerAdjustGoals => '$apiBaseUrl/workouts/nutrition-goals/trainer-adjust/';
  static String get weightCheckIns => '$apiBaseUrl/workouts/weight-checkins/';
  static String get latestWeightCheckIn => '$apiBaseUrl/workouts/weight-checkins/latest/';

  // Macro presets endpoints
  static String get macroPresets => '$apiBaseUrl/workouts/macro-presets/';
  static String macroPreset(int id) => '$apiBaseUrl/workouts/macro-presets/$id/';
  static String macroPresetsForTrainee(int traineeId) =>
      '$apiBaseUrl/workouts/macro-presets/?trainee_id=$traineeId';
  static String get allMacroPresets => '$apiBaseUrl/workouts/macro-presets/all_presets/';
  static String copyMacroPreset(int presetId) =>
      '$apiBaseUrl/workouts/macro-presets/$presetId/copy_to/';

  // Trainer endpoints
  static String get trainerDashboard => '$apiBaseUrl/trainer/dashboard/';
  static String get trainerStats => '$apiBaseUrl/trainer/dashboard/stats/';
  static String get trainerTrainees => '$apiBaseUrl/trainer/trainees/';
  static String get trainerInvitations => '$apiBaseUrl/trainer/invitations/';
  static String get startImpersonation => '$apiBaseUrl/trainer/impersonate/';
  static String get endImpersonation => '$apiBaseUrl/trainer/impersonate/end/';
  static String get programTemplates => '$apiBaseUrl/trainer/program-templates/';
  static String assignProgramTemplate(int templateId) =>
      '$apiBaseUrl/trainer/program-templates/$templateId/assign/';
  static String get trainerAnalyticsAdherence => '$apiBaseUrl/trainer/analytics/adherence/';
  static String get trainerAnalyticsProgress => '$apiBaseUrl/trainer/analytics/progress/';
  static String get trainerMcpToken => '$apiBaseUrl/trainer/mcp/token/';
  static String markMissedDay(int programId) =>
      '$apiBaseUrl/trainer/programs/$programId/mark-missed/';
  static String traineeLayoutConfig(int traineeId) =>
      '$apiBaseUrl/trainer/trainees/$traineeId/layout-config/';

  // Trainer notification endpoints
  static String get trainerNotifications => '$apiBaseUrl/trainer/notifications/';
  static String get trainerNotificationsUnreadCount => '$apiBaseUrl/trainer/notifications/unread-count/';
  static String get trainerNotificationsMarkAllRead => '$apiBaseUrl/trainer/notifications/mark-all-read/';
  static String trainerNotificationRead(int id) => '$apiBaseUrl/trainer/notifications/$id/read/';
  static String trainerNotificationDelete(int id) => '$apiBaseUrl/trainer/notifications/$id/';

  // Trainer branding endpoints
  static String get trainerBranding => '$apiBaseUrl/trainer/branding/';
  static String get trainerBrandingLogo => '$apiBaseUrl/trainer/branding/logo/';

  // Trainee branding endpoint
  static String get myBranding => '$apiBaseUrl/users/my-branding/';

  // AI Chat endpoints
  static String get trainerAiChat => '$apiBaseUrl/trainer/ai/chat/';
  static String trainerAiContext(int traineeId) =>
      '$apiBaseUrl/trainer/ai/context/$traineeId/';

  // Feature request endpoints
  static String get featureRequests => '$apiBaseUrl/features/';

  // Admin endpoints
  static String get adminDashboard => '$apiBaseUrl/admin/dashboard/';
  static String get adminTrainers => '$apiBaseUrl/admin/trainers/';
  static String get adminSubscriptions => '$apiBaseUrl/admin/subscriptions/';
  static String get adminPastDue => '$apiBaseUrl/admin/past-due/';
  static String get adminUpcomingPayments => '$apiBaseUrl/admin/upcoming-payments/';

  // Admin tier management
  static String get adminTiers => '$apiBaseUrl/admin/tiers/';
  static String get publicTiers => '$apiBaseUrl/admin/tiers/public/';

  // Admin impersonation (login as trainer)
  static String adminImpersonateTrainer(int trainerId) =>
      '$apiBaseUrl/admin/impersonate/$trainerId/';
  static String get adminEndImpersonation => '$apiBaseUrl/admin/impersonate/end/';

  // Admin user management
  static String get adminUsers => '$apiBaseUrl/admin/users/';
  static String get adminCreateUser => '$apiBaseUrl/admin/users/create/';
  static String adminUserDetail(int userId) => '$apiBaseUrl/admin/users/$userId/';

  // Admin coupon management
  static String get adminCoupons => '$apiBaseUrl/admin/coupons/';

  // Ambassador endpoints
  static String get ambassadorDashboard => '$apiBaseUrl/ambassador/dashboard/';
  static String get ambassadorReferrals => '$apiBaseUrl/ambassador/referrals/';
  static String get ambassadorReferralCode => '$apiBaseUrl/ambassador/referral-code/';

  // Admin ambassador management
  static String get adminAmbassadors => '$apiBaseUrl/admin/ambassadors/';
  static String get adminCreateAmbassador => '$apiBaseUrl/admin/ambassadors/create/';
  static String adminAmbassadorDetail(int id) => '$apiBaseUrl/admin/ambassadors/$id/';

  // Payment endpoints (Stripe Connect)
  static String get stripeConnectOnboard => '$apiBaseUrl/payments/connect/onboard/';
  static String get stripeConnectStatus => '$apiBaseUrl/payments/connect/status/';
  static String get stripeConnectDashboard => '$apiBaseUrl/payments/connect/dashboard/';

  // Trainer pricing endpoints
  static String get trainerPricing => '$apiBaseUrl/payments/pricing/';
  static String trainerPublicPricing(int trainerId) =>
      '$apiBaseUrl/payments/trainers/$trainerId/pricing/';

  // Checkout endpoints
  static String get checkoutSubscription => '$apiBaseUrl/payments/checkout/subscription/';
  static String get checkoutOneTime => '$apiBaseUrl/payments/checkout/one-time/';

  // Trainee subscription endpoints
  static String get traineeSubscription => '$apiBaseUrl/payments/my-subscription/';
  static String get traineePayments => '$apiBaseUrl/payments/my-payments/';

  // Trainer payment view endpoints
  static String get trainerPayments => '$apiBaseUrl/payments/trainer/payments/';
  static String get trainerSubscribers => '$apiBaseUrl/payments/trainer/subscribers/';

  // Trainer coupon management
  static String get trainerCoupons => '$apiBaseUrl/payments/trainer/coupons/';

  // Coupon validation
  static String get validateCoupon => '$apiBaseUrl/payments/coupons/validate/';

  // Calendar integration endpoints
  static String get calendarConnections => '$apiBaseUrl/calendar/connections/';
  static String get googleAuthUrl => '$apiBaseUrl/calendar/google/auth/';
  static String get googleCallback => '$apiBaseUrl/calendar/google/callback/';
  static String get microsoftAuthUrl => '$apiBaseUrl/calendar/microsoft/auth/';
  static String get microsoftCallback => '$apiBaseUrl/calendar/microsoft/callback/';
  static String calendarDisconnect(String provider) =>
      '$apiBaseUrl/calendar/$provider/disconnect/';
  static String calendarSync(String provider) =>
      '$apiBaseUrl/calendar/$provider/sync/';
  static String get calendarEvents => '$apiBaseUrl/calendar/events/';
  static String get calendarEventCreate => '$apiBaseUrl/calendar/events/create/';
  static String get trainerAvailability => '$apiBaseUrl/calendar/availability/';
  static String trainerAvailabilityDetail(int id) =>
      '$apiBaseUrl/calendar/availability/$id/';

  // Headers (these can stay const)
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}
