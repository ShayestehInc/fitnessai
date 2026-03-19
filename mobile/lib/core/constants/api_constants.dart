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

  // Password reset endpoints
  static String get resetPassword => '$apiBaseUrl/auth/users/reset_password/';
  static String get resetPasswordConfirm => '$apiBaseUrl/auth/users/reset_password_confirm/';

  // Password change endpoint (Djoser)
  static String get setPassword => '$apiBaseUrl/auth/users/set_password/';

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
  static String get weeklyProgress => '$apiBaseUrl/workouts/daily-logs/weekly-progress/';
  static String get workoutHistory => '$apiBaseUrl/workouts/daily-logs/workout-history/';
  static String workoutHistoryDetail(int logId) =>
      '$apiBaseUrl/workouts/daily-logs/$logId/workout-detail/';
  static String editMealEntry(int logId) => '$apiBaseUrl/workouts/daily-logs/$logId/edit-meal-entry/';
  static String deleteMealEntry(int logId) => '$apiBaseUrl/workouts/daily-logs/$logId/delete-meal-entry/';
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

  // Nutrition template endpoints
  static String get nutritionTemplates =>
      '$apiBaseUrl/workouts/nutrition-templates/';
  static String nutritionTemplateDetail(int id) =>
      '$apiBaseUrl/workouts/nutrition-templates/$id/';
  static String get systemNutritionTemplates =>
      '$apiBaseUrl/workouts/nutrition-templates/system/';
  static String get nutritionTemplateAssignments =>
      '$apiBaseUrl/workouts/nutrition-template-assignments/';
  static String nutritionTemplateAssignmentDetail(int id) =>
      '$apiBaseUrl/workouts/nutrition-template-assignments/$id/';
  static String nutritionTemplateAssignmentRecalculate(int id) =>
      '$apiBaseUrl/workouts/nutrition-template-assignments/$id/recalculate/';
  static String get nutritionDayPlans =>
      '$apiBaseUrl/workouts/nutrition-day-plans/';
  static String get nutritionDayPlansWeek =>
      '$apiBaseUrl/workouts/nutrition-day-plans/week/';
  static String nutritionDayPlanOverride(int id) =>
      '$apiBaseUrl/workouts/nutrition-day-plans/$id/override/';

  // Food items endpoints
  static String get foodItems => '$apiBaseUrl/workouts/food-items/';
  static String foodItemDetail(int id) => '$apiBaseUrl/workouts/food-items/$id/';
  static String foodItemBarcode(String barcode) =>
      '$apiBaseUrl/workouts/food-items/barcode/$barcode/';
  static String get recentFoodItems => '$apiBaseUrl/workouts/food-items/recent/';

  // Meal log endpoints
  static String get mealLogs => '$apiBaseUrl/workouts/meal-logs/';
  static String get mealLogSummary => '$apiBaseUrl/workouts/meal-logs/summary/';
  static String get mealLogQuickAdd => '$apiBaseUrl/workouts/meal-logs/quick-add/';
  static String mealLogEntryDelete(int entryId) =>
      '$apiBaseUrl/workouts/meal-logs/entries/$entryId/';

  // Active nutrition template assignment
  static String get activeNutritionAssignment =>
      '$apiBaseUrl/workouts/nutrition-template-assignments/active/';

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
  static String get generateProgram => '$apiBaseUrl/trainer/program-templates/generate/';
  static String get modifyProgram => '$apiBaseUrl/trainer/program-templates/modify/';
  static String assignProgramTemplate(int templateId) =>
      '$apiBaseUrl/trainer/program-templates/$templateId/assign/';
  static String get trainerAnalyticsAdherence => '$apiBaseUrl/trainer/analytics/adherence/';
  static String get trainerAnalyticsProgress => '$apiBaseUrl/trainer/analytics/progress/';
  static String get trainerAnalyticsRetention => '$apiBaseUrl/trainer/analytics/retention/';
  static String get trainerAnalyticsAtRisk => '$apiBaseUrl/trainer/analytics/at-risk/';
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
  static String adminAmbassadorCommissionApprove(int ambassadorId, int commissionId) =>
      '$apiBaseUrl/admin/ambassadors/$ambassadorId/commissions/$commissionId/approve/';
  static String adminAmbassadorCommissionPay(int ambassadorId, int commissionId) =>
      '$apiBaseUrl/admin/ambassadors/$ambassadorId/commissions/$commissionId/pay/';
  static String adminAmbassadorBulkApprove(int ambassadorId) =>
      '$apiBaseUrl/admin/ambassadors/$ambassadorId/commissions/bulk-approve/';
  static String adminAmbassadorBulkPay(int ambassadorId) =>
      '$apiBaseUrl/admin/ambassadors/$ambassadorId/commissions/bulk-pay/';

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

  // Community endpoints (trainee-facing)
  static String get communityAnnouncements => '$apiBaseUrl/community/announcements/';
  static String get communityAnnouncementsUnread => '$apiBaseUrl/community/announcements/unread-count/';
  static String get communityAnnouncementsMarkRead => '$apiBaseUrl/community/announcements/mark-read/';
  static String get communityAchievements => '$apiBaseUrl/community/achievements/';
  static String get communityAchievementsRecent => '$apiBaseUrl/community/achievements/recent/';
  static String get communityFeed => '$apiBaseUrl/community/feed/';
  static String communityPostDelete(int postId) => '$apiBaseUrl/community/feed/$postId/';
  static String communityPostReact(int postId) => '$apiBaseUrl/community/feed/$postId/react/';

  // Trainer announcement endpoints
  static String get trainerAnnouncements => '$apiBaseUrl/trainer/announcements/';
  static String trainerAnnouncementDetail(int id) => '$apiBaseUrl/trainer/announcements/$id/';

  // Trainer leaderboard settings
  static String get trainerLeaderboardSettings => '$apiBaseUrl/trainer/leaderboard-settings/';

  // Community comments
  static String communityPostComments(int postId) => '$apiBaseUrl/community/feed/$postId/comments/';
  static String communityCommentDelete(int postId, int commentId) =>
      '$apiBaseUrl/community/feed/$postId/comments/$commentId/';

  // Community spaces
  static String get communitySpaces => '$apiBaseUrl/community/spaces/';
  static String communitySpaceDetail(int spaceId) =>
      '$apiBaseUrl/community/spaces/$spaceId/';
  static String communitySpaceJoin(int spaceId) =>
      '$apiBaseUrl/community/spaces/$spaceId/join/';
  static String communitySpaceLeave(int spaceId) =>
      '$apiBaseUrl/community/spaces/$spaceId/leave/';
  static String communitySpaceMembers(int spaceId) =>
      '$apiBaseUrl/community/spaces/$spaceId/members/';

  // Community bookmarks
  static String get communityBookmarkToggle => '$apiBaseUrl/community/bookmarks/toggle/';
  static String get communityBookmarks => '$apiBaseUrl/community/bookmarks/';
  static String get communityBookmarkCollections => '$apiBaseUrl/community/bookmark-collections/';

  // Community leaderboard
  static String get communityLeaderboard => '$apiBaseUrl/community/leaderboard/';

  // Device token (push notifications)
  static String get deviceToken => '$apiBaseUrl/users/device-token/';

  // Leaderboard opt-in
  static String get leaderboardOptIn => '$apiBaseUrl/users/leaderboard-opt-in/';

  // Notification preferences
  static String get notificationPreferences => '$apiBaseUrl/users/notification-preferences/';

  // Ambassador Stripe Connect
  static String get ambassadorConnectStatus => '$apiBaseUrl/ambassador/connect/status/';
  static String get ambassadorConnectOnboard => '$apiBaseUrl/ambassador/connect/onboard/';
  static String get ambassadorConnectReturn => '$apiBaseUrl/ambassador/connect/return/';
  static String get ambassadorPayouts => '$apiBaseUrl/ambassador/payouts/';

  // Admin ambassador payout
  static String adminAmbassadorPayout(int ambassadorId) =>
      '$apiBaseUrl/admin/ambassadors/$ambassadorId/payout/';

  // Messaging endpoints
  static String get messagingConversations => '$apiBaseUrl/messaging/conversations/';
  static String get messagingStartConversation => '$apiBaseUrl/messaging/conversations/start/';
  static String messagingConversationMessages(int conversationId) =>
      '$apiBaseUrl/messaging/conversations/$conversationId/messages/';
  static String messagingConversationSend(int conversationId) =>
      '$apiBaseUrl/messaging/conversations/$conversationId/send/';
  static String messagingMarkRead(int conversationId) =>
      '$apiBaseUrl/messaging/conversations/$conversationId/read/';
  // PATCH to edit, DELETE to delete — same resource URL, different HTTP methods.
  static String messagingMessageDetail(int conversationId, int messageId) =>
      '$apiBaseUrl/messaging/conversations/$conversationId/messages/$messageId/';

  // Convenience aliases for semantic clarity at call sites.
  static String messagingEditMessage(int conversationId, int messageId) =>
      messagingMessageDetail(conversationId, messageId);
  static String messagingDeleteMessage(int conversationId, int messageId) =>
      messagingMessageDetail(conversationId, messageId);
  static String get messagingUnreadCount => '$apiBaseUrl/messaging/unread-count/';

  // WebSocket
  static String get wsBaseUrl {
    final base = baseUrl.replaceFirst('http', 'ws');
    return '$base/ws';
  }
  static String get wsCommunityFeed => '$wsBaseUrl/community/feed/';
  static String wsMessaging(int conversationId) =>
      '$wsBaseUrl/messaging/$conversationId/';

  // Quick-log & workout template endpoints
  static String get workoutTemplates => '$apiBaseUrl/workouts/workout-templates/';
  static String get quickLog => '$apiBaseUrl/workouts/daily-logs/quick-log/';
  static String get completeRestDay => '$apiBaseUrl/workouts/daily-logs/complete-rest-day/';
  static String get barcodeLookup => '$apiBaseUrl/workouts/daily-logs/barcode-lookup/';
  static String shareCard(int logId) => '$apiBaseUrl/workouts/daily-logs/$logId/share-card/';
  static String progressionSuggestions(int programId) => '$apiBaseUrl/workouts/programs/$programId/progression-suggestions/';
  static String deloadCheck(int programId) => '$apiBaseUrl/workouts/programs/$programId/deload-check/';
  static String applyDeload(int programId) => '$apiBaseUrl/workouts/programs/$programId/apply-deload/';
  static String exportPdf(int programId) => '$apiBaseUrl/workouts/programs/$programId/export-pdf/';

  // Lift tracking endpoints
  static String get liftSetLogs => '$apiBaseUrl/workouts/lift-set-logs/';
  static String get liftMaxes => '$apiBaseUrl/workouts/lift-maxes/';
  static String get liftMaxHistory => '$apiBaseUrl/workouts/lift-maxes/history/';
  static String get workloadSession => '$apiBaseUrl/workouts/workload/session/';
  static String get workloadWeekly => '$apiBaseUrl/workouts/workload/weekly/';
  static String get workloadTrends => '$apiBaseUrl/workouts/workload/trends/';

  // Training Plan endpoints
  static String get trainingPlans => '$apiBaseUrl/workouts/training-plans/';
  static String trainingPlanDetail(String id) =>
      '$apiBaseUrl/workouts/training-plans/$id/';
  static String get planSessions => '$apiBaseUrl/workouts/plan-sessions/';
  static String planSessionDetail(String id) =>
      '$apiBaseUrl/workouts/plan-sessions/$id/';
  static String get planSlots => '$apiBaseUrl/workouts/plan-slots/';
  static String planSlotDetail(String id) =>
      '$apiBaseUrl/workouts/plan-slots/$id/';
  static String get splitTemplates => '$apiBaseUrl/workouts/split-templates/';
  static String get modalities => '$apiBaseUrl/workouts/modalities/';

  // Builder endpoints
  static String get quickBuild =>
      '$apiBaseUrl/workouts/training-plans/quick-build/';
  static String get builderStart =>
      '$apiBaseUrl/workouts/training-plans/builder/start/';
  static String builderAdvance(String planId) =>
      '$apiBaseUrl/workouts/training-plans/$planId/builder/advance/';
  static String convertToProgram(String planId) =>
      '$apiBaseUrl/workouts/training-plans/$planId/convert-to-program/';
  static String builderState(String planId) =>
      '$apiBaseUrl/workouts/training-plans/$planId/builder/state/';

  // Progression Profile endpoints
  static String get progressionProfiles =>
      '$apiBaseUrl/workouts/progression-profiles/';
  static String progressionProfileDetail(int id) =>
      '$apiBaseUrl/workouts/progression-profiles/$id/';
  static String get progressionSuggestionsList =>
      '$apiBaseUrl/workouts/progression-suggestions/';
  static String progressionSuggestionApprove(int id) =>
      '$apiBaseUrl/workouts/progression-suggestions/$id/approve/';
  static String progressionSuggestionDismiss(int id) =>
      '$apiBaseUrl/workouts/progression-suggestions/$id/dismiss/';

  // Progress photo endpoints
  static String get progressPhotos => '$apiBaseUrl/workouts/progress-photos/';
  static String get progressPhotosCompare => '$apiBaseUrl/workouts/progress-photos/compare/';

  // Habit tracking endpoints
  static String get habits => '$apiBaseUrl/workouts/habits/';
  static String get habitToggle => '$apiBaseUrl/workouts/habits/toggle/';
  static String get habitStreaks => '$apiBaseUrl/workouts/habits/streaks/';
  static String get habitDaily => '$apiBaseUrl/workouts/habits/daily/';

  // Check-in template endpoints
  static String get checkinTemplates => '$apiBaseUrl/workouts/checkin-templates/';
  static String checkinTemplateAssign(int templateId) => '$apiBaseUrl/workouts/checkin-templates/$templateId/assign/';
  static String get checkinResponses => '$apiBaseUrl/workouts/checkin-responses/';
  static String get checkinResponsesPending => '$apiBaseUrl/workouts/checkin-responses/pending/';

  // Community Classroom endpoints
  static String get communityCourses => '$apiBaseUrl/community/courses/';
  static String communityCourseDetail(int id) => '$apiBaseUrl/community/courses/$id/';
  static String communityCourseEnroll(int id) => '$apiBaseUrl/community/courses/$id/enroll/';
  static String get communityMyEnrollments => '$apiBaseUrl/community/my-enrollments/';
  static String communityLessonProgress(int courseId, int lessonId) =>
      '$apiBaseUrl/community/courses/$courseId/lessons/$lessonId/progress/';

  // Community Events endpoints
  static String get communityEvents => '$apiBaseUrl/community/events/';
  static String communityEventDetail(int id) => '$apiBaseUrl/community/events/$id/';
  static String communityEventRsvp(int id) => '$apiBaseUrl/community/events/$id/rsvp/';

  // Community Report endpoint
  static String get communityReport => '$apiBaseUrl/community/report/';

  // Trainer Course endpoints
  static String get trainerCourses => '$apiBaseUrl/trainer/courses/';
  static String trainerCourseDetail(int id) => '$apiBaseUrl/trainer/courses/$id/';
  static String trainerCourseLessons(int courseId) => '$apiBaseUrl/trainer/courses/$courseId/lessons/';
  static String trainerLessonDetail(int courseId, int lessonId) =>
      '$apiBaseUrl/trainer/courses/$courseId/lessons/$lessonId/';

  // Trainer Event endpoints
  static String get trainerEvents => '$apiBaseUrl/trainer/events/';
  static String trainerEventDetail(int id) => '$apiBaseUrl/trainer/events/$id/';
  static String trainerEventStatus(int id) => '$apiBaseUrl/trainer/events/$id/status/';

  // Trainer Moderation endpoints
  static String get trainerModerationReports => '$apiBaseUrl/trainer/moderation/reports/';
  static String trainerReportReview(int id) => '$apiBaseUrl/trainer/moderation/reports/$id/review/';
  static String get trainerModerationBans => '$apiBaseUrl/trainer/moderation/bans/';
  static String trainerUnban(int userId) => '$apiBaseUrl/trainer/moderation/bans/$userId/';
  static String get trainerAutoModRules => '$apiBaseUrl/trainer/moderation/rules/';
  static String trainerAutoModRuleDetail(int id) => '$apiBaseUrl/trainer/moderation/rules/$id/';

  // Trainer Community Config endpoint
  static String get trainerCommunityConfig => '$apiBaseUrl/trainer/community-config/';

  // Session runner endpoints
  static String get sessions => '$apiBaseUrl/workouts/sessions/';
  static String get sessionsActive => '$apiBaseUrl/workouts/sessions/active/';
  static String get sessionsStart => '$apiBaseUrl/workouts/sessions/start/';
  static String sessionDetail(String id) =>
      '$apiBaseUrl/workouts/sessions/$id/';
  static String sessionLogSet(String id) =>
      '$apiBaseUrl/workouts/sessions/$id/log-set/';
  static String sessionSkipSet(String id) =>
      '$apiBaseUrl/workouts/sessions/$id/skip-set/';
  static String sessionComplete(String id) =>
      '$apiBaseUrl/workouts/sessions/$id/complete/';
  static String sessionAbandon(String id) =>
      '$apiBaseUrl/workouts/sessions/$id/abandon/';

  // Lift logging detail endpoints (v6.5)
  static String liftSetLogDetail(String id) =>
      '$apiBaseUrl/workouts/lift-set-logs/$id/';
  static String liftMaxDetail(String id) =>
      '$apiBaseUrl/workouts/lift-maxes/$id/';
  static String get liftMaxPrescribe => '$apiBaseUrl/workouts/lift-maxes/prescribe/';

  // Workload exercise endpoint (v6.5)
  static String get workloadExercise => '$apiBaseUrl/workouts/workload/exercise/';

  // Session feedback endpoints (v6.5)
  static String get sessionFeedback => '$apiBaseUrl/workouts/session-feedback/';
  static String sessionFeedbackSubmit(String sessionId) =>
      '$apiBaseUrl/workouts/session-feedback/submit/$sessionId/';
  static String sessionFeedbackForSession(String sessionId) =>
      '$apiBaseUrl/workouts/session-feedback/for-session/$sessionId/';
  static String get painEvents => '$apiBaseUrl/workouts/pain-events/';
  static String get painEventLog => '$apiBaseUrl/workouts/pain-events/log/';
  static String get routingRules => '$apiBaseUrl/workouts/routing-rules/';
  static String get routingRulesDefaults => '$apiBaseUrl/workouts/routing-rules/defaults/';
  static String get routingRulesInitialize => '$apiBaseUrl/workouts/routing-rules/initialize/';

  // Voice memo endpoints (v6.5)
  static String get voiceMemoUpload => '$apiBaseUrl/workouts/voice-memos/';
  static String get voiceMemoList => '$apiBaseUrl/workouts/voice-memos/list/';
  static String voiceMemoDetail(String id) =>
      '$apiBaseUrl/workouts/voice-memos/$id/';

  // Video analysis endpoints (v6.5)
  static String get videoAnalysisUpload => '$apiBaseUrl/workouts/video-analysis/';
  static String get videoAnalysisList => '$apiBaseUrl/workouts/video-analysis/list/';
  static String videoAnalysisDetail(String id) =>
      '$apiBaseUrl/workouts/video-analysis/$id/';
  static String videoAnalysisConfirm(String id) =>
      '$apiBaseUrl/workouts/video-analysis/$id/confirm/';

  // Decision log endpoints (v6.5)
  static String get decisionLogs => '$apiBaseUrl/workouts/decision-logs/';
  static String decisionLogDetail(String id) =>
      '$apiBaseUrl/workouts/decision-logs/$id/';
  static String decisionLogUndo(String id) =>
      '$apiBaseUrl/workouts/decision-logs/$id/undo/';

  // Program import endpoints (v6.5)
  static String get programImports => '$apiBaseUrl/workouts/program-imports/';
  static String get programImportUpload => '$apiBaseUrl/workouts/program-imports/upload/';
  static String programImportDetail(String draftId) =>
      '$apiBaseUrl/workouts/program-imports/$draftId/';
  static String programImportConfirm(String draftId) =>
      '$apiBaseUrl/workouts/program-imports/$draftId/confirm/';

  // Exercise auto-tagging endpoints (v6.5)
  static String exerciseAutoTag(int exerciseId) =>
      '$apiBaseUrl/workouts/exercises/$exerciseId/auto-tag/';
  static String exerciseAutoTagDraft(int exerciseId) =>
      '$apiBaseUrl/workouts/exercises/$exerciseId/auto-tag-draft/';
  static String exerciseAutoTagApply(int exerciseId) =>
      '$apiBaseUrl/workouts/exercises/$exerciseId/auto-tag-draft/apply/';
  static String exerciseAutoTagReject(int exerciseId) =>
      '$apiBaseUrl/workouts/exercises/$exerciseId/auto-tag-draft/reject/';
  static String exerciseAutoTagRetry(int exerciseId) =>
      '$apiBaseUrl/workouts/exercises/$exerciseId/auto-tag-draft/retry/';
  static String exerciseTagHistory(int exerciseId) =>
      '$apiBaseUrl/workouts/exercises/$exerciseId/tag-history/';

  // Trainer analytics endpoints (v6.5)
  static String get trainerAnalyticsCorrelations =>
      '$apiBaseUrl/trainer/analytics/correlations/';
  static String trainerTraineePatterns(int traineeId) =>
      '$apiBaseUrl/trainer/analytics/trainee/$traineeId/patterns/';
  static String get trainerCohortAnalysis =>
      '$apiBaseUrl/trainer/analytics/cohort/';
  static String get trainerAnalyticsRevenue => '$apiBaseUrl/trainer/analytics/revenue/';
  static String get trainerAnalyticsAdherenceTrends =>
      '$apiBaseUrl/trainer/analytics/adherence/trends/';

  // Trainer audit endpoints (v6.5)
  static String get trainerAuditSummary => '$apiBaseUrl/trainer/audit/summary/';
  static String get trainerAuditTimeline => '$apiBaseUrl/trainer/audit/timeline/';

  // Trainer comprehensive export endpoints (v6.5)
  static String get trainerExportDecisionLogs => '$apiBaseUrl/trainer/export/decision-logs/';
  static String get trainerExportPayments => '$apiBaseUrl/trainer/export/payments/';
  static String get trainerExportSubscribers => '$apiBaseUrl/trainer/export/subscribers/';
  static String get trainerExportTrainees => '$apiBaseUrl/trainer/export/trainees/';
  static String trainerExportTraineeWorkout(int traineeId) =>
      '$apiBaseUrl/trainer/export/trainee/$traineeId/workout-history/';
  static String trainerExportTraineeNutrition(int traineeId) =>
      '$apiBaseUrl/trainer/export/trainee/$traineeId/nutrition-history/';
  static String trainerExportTraineeProgress(int traineeId) =>
      '$apiBaseUrl/trainer/export/trainee/$traineeId/progress/';

  // Anatomy / Muscle Reference endpoints
  static String get muscles => '$apiBaseUrl/workouts/muscles/';
  static String muscleDetail(String slug) => '$apiBaseUrl/workouts/muscles/$slug/';
  static String muscleExercises(String slug) => '$apiBaseUrl/workouts/muscles/$slug/exercises/';
  static String get muscleCoverage => '$apiBaseUrl/workouts/muscle-coverage/';

  // Headers (these can stay const)
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}
