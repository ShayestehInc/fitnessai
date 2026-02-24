const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

// WebSocket base: derive ws(s) from the API base URL
function deriveWsBase(apiBase: string): string {
  try {
    const url = new URL(apiBase);
    const wsProtocol = url.protocol === "https:" ? "wss:" : "ws:";
    return `${wsProtocol}//${url.host}`;
  } catch {
    // Fallback for development
    return "ws://localhost:8000";
  }
}

const WS_BASE = deriveWsBase(API_BASE);

export const API_URLS = {
  // Auth
  LOGIN: `${API_BASE}/api/auth/jwt/create/`,
  TOKEN_REFRESH: `${API_BASE}/api/auth/jwt/refresh/`,
  CURRENT_USER: `${API_BASE}/api/auth/users/me/`,

  // Trainer Dashboard
  DASHBOARD_STATS: `${API_BASE}/api/trainer/dashboard/stats/`,
  DASHBOARD_OVERVIEW: `${API_BASE}/api/trainer/dashboard/`,

  // Trainees
  TRAINEES: `${API_BASE}/api/trainer/trainees/`,
  traineeDetail: (id: number) => `${API_BASE}/api/trainer/trainees/${id}/`,
  traineeActivity: (id: number) =>
    `${API_BASE}/api/trainer/trainees/${id}/activity/`,

  // Notifications
  NOTIFICATIONS: `${API_BASE}/api/trainer/notifications/`,
  NOTIFICATIONS_UNREAD_COUNT: `${API_BASE}/api/trainer/notifications/unread-count/`,
  NOTIFICATIONS_MARK_ALL_READ: `${API_BASE}/api/trainer/notifications/mark-all-read/`,
  notificationRead: (id: number) =>
    `${API_BASE}/api/trainer/notifications/${id}/read/`,

  // Invitations
  INVITATIONS: `${API_BASE}/api/trainer/invitations/`,
  invitationDetail: (id: number) =>
    `${API_BASE}/api/trainer/invitations/${id}/`,
  invitationResend: (id: number) =>
    `${API_BASE}/api/trainer/invitations/${id}/resend/`,

  // Settings / Profile
  UPDATE_PROFILE: `${API_BASE}/api/users/me/`,
  PROFILE_IMAGE: `${API_BASE}/api/users/profile-image/`,
  CHANGE_PASSWORD: `${API_BASE}/api/auth/users/set_password/`,

  // Progress / Analytics
  traineeProgress: (id: number) =>
    `${API_BASE}/api/trainer/trainees/${id}/progress/`,
  ANALYTICS_ADHERENCE: `${API_BASE}/api/trainer/analytics/adherence/`,
  ANALYTICS_ADHERENCE_TRENDS: `${API_BASE}/api/trainer/analytics/adherence/trends/`,
  ANALYTICS_PROGRESS: `${API_BASE}/api/trainer/analytics/progress/`,
  ANALYTICS_REVENUE: `${API_BASE}/api/trainer/analytics/revenue/`,

  // CSV Exports
  EXPORT_PAYMENTS: `${API_BASE}/api/trainer/export/payments/`,
  EXPORT_SUBSCRIBERS: `${API_BASE}/api/trainer/export/subscribers/`,
  EXPORT_TRAINEES: `${API_BASE}/api/trainer/export/trainees/`,

  // Programs & Exercises
  PROGRAM_TEMPLATES: `${API_BASE}/api/trainer/program-templates/`,
  programTemplateDetail: (id: number) =>
    `${API_BASE}/api/trainer/program-templates/${id}/`,
  programTemplateAssign: (id: number) =>
    `${API_BASE}/api/trainer/program-templates/${id}/assign/`,
  GENERATE_PROGRAM: `${API_BASE}/api/trainer/program-templates/generate/`,
  EXERCISES: `${API_BASE}/api/workouts/exercises/`,

  // Admin Dashboard
  ADMIN_DASHBOARD: `${API_BASE}/api/admin/dashboard/`,

  // Admin Trainers
  ADMIN_TRAINERS: `${API_BASE}/api/admin/trainers/`,

  // Admin Impersonation
  adminImpersonate: (trainerId: number) =>
    `${API_BASE}/api/admin/impersonate/${trainerId}/`,
  ADMIN_IMPERSONATE_END: `${API_BASE}/api/admin/impersonate/end/`,

  // Admin Users
  ADMIN_USERS: `${API_BASE}/api/admin/users/`,
  ADMIN_USERS_CREATE: `${API_BASE}/api/admin/users/create/`,
  adminUserDetail: (userId: number) =>
    `${API_BASE}/api/admin/users/${userId}/`,

  // Admin Subscriptions
  ADMIN_SUBSCRIPTIONS: `${API_BASE}/api/admin/subscriptions/`,
  adminSubscriptionDetail: (id: number) =>
    `${API_BASE}/api/admin/subscriptions/${id}/`,
  adminSubscriptionChangeTier: (id: number) =>
    `${API_BASE}/api/admin/subscriptions/${id}/change-tier/`,
  adminSubscriptionChangeStatus: (id: number) =>
    `${API_BASE}/api/admin/subscriptions/${id}/change-status/`,
  adminSubscriptionUpdateNotes: (id: number) =>
    `${API_BASE}/api/admin/subscriptions/${id}/update-notes/`,
  adminSubscriptionRecordPayment: (id: number) =>
    `${API_BASE}/api/admin/subscriptions/${id}/record-payment/`,
  adminSubscriptionPaymentHistory: (id: number) =>
    `${API_BASE}/api/admin/subscriptions/${id}/payment-history/`,
  adminSubscriptionChangeHistory: (id: number) =>
    `${API_BASE}/api/admin/subscriptions/${id}/change-history/`,
  ADMIN_PAST_DUE: `${API_BASE}/api/admin/past-due/`,
  ADMIN_UPCOMING_PAYMENTS: `${API_BASE}/api/admin/upcoming-payments/`,

  // Admin Tiers
  ADMIN_TIERS: `${API_BASE}/api/admin/tiers/`,
  adminTierDetail: (id: number) =>
    `${API_BASE}/api/admin/tiers/${id}/`,
  ADMIN_TIERS_SEED_DEFAULTS: `${API_BASE}/api/admin/tiers/seed-defaults/`,
  adminTierToggleActive: (id: number) =>
    `${API_BASE}/api/admin/tiers/${id}/toggle-active/`,

  // Admin Coupons
  ADMIN_COUPONS: `${API_BASE}/api/admin/coupons/`,
  adminCouponDetail: (id: number) =>
    `${API_BASE}/api/admin/coupons/${id}/`,
  adminCouponRevoke: (id: number) =>
    `${API_BASE}/api/admin/coupons/${id}/revoke/`,
  adminCouponReactivate: (id: number) =>
    `${API_BASE}/api/admin/coupons/${id}/reactivate/`,
  adminCouponUsages: (id: number) =>
    `${API_BASE}/api/admin/coupons/${id}/usages/`,

  // Trainer Announcements
  ANNOUNCEMENTS: `${API_BASE}/api/trainer/announcements/`,
  announcementDetail: (id: number) =>
    `${API_BASE}/api/trainer/announcements/${id}/`,

  // Trainer AI Chat (legacy stateless)
  AI_CHAT: `${API_BASE}/api/trainer/ai/chat/`,
  AI_CONTEXT: (traineeId: number) =>
    `${API_BASE}/api/trainer/ai/context/${traineeId}/`,
  AI_PROVIDERS: `${API_BASE}/api/trainer/ai/providers/`,

  // AI Chat Threads (persistent)
  AI_THREADS: `${API_BASE}/api/trainer/ai/threads/`,
  aiThreadDetail: (id: number) =>
    `${API_BASE}/api/trainer/ai/threads/${id}/`,
  aiThreadSend: (id: number) =>
    `${API_BASE}/api/trainer/ai/threads/${id}/send/`,

  // Trainer Branding
  TRAINER_BRANDING: `${API_BASE}/api/trainer/branding/`,
  TRAINER_BRANDING_LOGO: `${API_BASE}/api/trainer/branding/logo/`,

  // Trainee Goals
  traineeGoals: (id: number) =>
    `${API_BASE}/api/trainer/trainees/${id}/goals/`,

  // Remove Trainee
  traineeRemove: (id: number) =>
    `${API_BASE}/api/trainer/trainees/${id}/remove/`,

  // Trainee Layout Config
  traineeLayoutConfig: (traineeId: number) =>
    `${API_BASE}/api/trainer/trainees/${traineeId}/layout-config/`,

  // Trainer Impersonation (trainee)
  trainerImpersonateStart: (traineeId: number) =>
    `${API_BASE}/api/trainer/impersonate/${traineeId}/start/`,
  TRAINER_IMPERSONATE_END: `${API_BASE}/api/trainer/impersonate/end/`,

  // Mark Missed Day
  programMarkMissed: (programId: number) =>
    `${API_BASE}/api/trainer/programs/${programId}/mark-missed/`,

  // Stripe Connect / Subscription
  STRIPE_CONNECT_STATUS: `${API_BASE}/api/payments/connect/status/`,
  STRIPE_CONNECT_ONBOARD: `${API_BASE}/api/payments/connect/onboard/`,
  STRIPE_CONNECT_DASHBOARD: `${API_BASE}/api/payments/connect/dashboard/`,
  TRAINER_PRICING: `${API_BASE}/api/payments/pricing/`,
  TRAINER_PAYMENTS: `${API_BASE}/api/payments/trainer/payments/`,
  TRAINER_SUBSCRIBERS: `${API_BASE}/api/payments/trainer/subscribers/`,

  // Calendar
  CALENDAR_CONNECTIONS: `${API_BASE}/api/calendar/connections/`,
  GOOGLE_CALENDAR_AUTH: `${API_BASE}/api/calendar/google/auth/`,
  CALENDAR_EVENTS: `${API_BASE}/api/calendar/events/`,
  calendarConnectionDetail: (id: number) =>
    `${API_BASE}/api/calendar/connections/${id}/`,

  // Feature Requests
  FEATURE_REQUESTS: `${API_BASE}/api/features/`,
  featureRequestDetail: (id: number) =>
    `${API_BASE}/api/features/${id}/`,
  featureRequestVote: (id: number) =>
    `${API_BASE}/api/features/${id}/vote/`,
  featureRequestComments: (id: number) =>
    `${API_BASE}/api/features/${id}/comments/`,

  // Leaderboard Settings
  LEADERBOARD_SETTINGS: `${API_BASE}/api/trainer/leaderboard-settings/`,

  // Admin Ambassadors
  ADMIN_AMBASSADORS: `${API_BASE}/api/admin/ambassadors/`,
  ADMIN_AMBASSADOR_CREATE: `${API_BASE}/api/admin/ambassadors/create/`,
  adminAmbassadorDetail: (id: number) =>
    `${API_BASE}/api/admin/ambassadors/${id}/`,
  adminCommissionApprove: (ambassadorId: number, commissionId: number) =>
    `${API_BASE}/api/admin/ambassadors/${ambassadorId}/commissions/${commissionId}/approve/`,
  adminCommissionPay: (ambassadorId: number, commissionId: number) =>
    `${API_BASE}/api/admin/ambassadors/${ambassadorId}/commissions/${commissionId}/pay/`,
  adminBulkApprove: (ambassadorId: number) =>
    `${API_BASE}/api/admin/ambassadors/${ambassadorId}/commissions/bulk-approve/`,
  adminBulkPay: (ambassadorId: number) =>
    `${API_BASE}/api/admin/ambassadors/${ambassadorId}/commissions/bulk-pay/`,
  adminTriggerPayout: (ambassadorId: number) =>
    `${API_BASE}/api/admin/ambassadors/${ambassadorId}/payout/`,

  // Messaging
  MESSAGING_CONVERSATIONS: `${API_BASE}/api/messaging/conversations/`,
  MESSAGING_START_CONVERSATION: `${API_BASE}/api/messaging/conversations/start/`,
  MESSAGING_UNREAD_COUNT: `${API_BASE}/api/messaging/unread-count/`,
  messagingMessages: (conversationId: number) =>
    `${API_BASE}/api/messaging/conversations/${conversationId}/messages/`,
  messagingSend: (conversationId: number) =>
    `${API_BASE}/api/messaging/conversations/${conversationId}/send/`,
  messagingMarkRead: (conversationId: number) =>
    `${API_BASE}/api/messaging/conversations/${conversationId}/read/`,
  // PATCH to edit, DELETE to delete — same resource URL, different HTTP methods.
  messagingMessageDetail: (conversationId: number, messageId: number) =>
    `${API_BASE}/api/messaging/conversations/${conversationId}/messages/${messageId}/`,
  messagingEditMessage: (conversationId: number, messageId: number) =>
    `${API_BASE}/api/messaging/conversations/${conversationId}/messages/${messageId}/`,
  messagingDeleteMessage: (conversationId: number, messageId: number) =>
    `${API_BASE}/api/messaging/conversations/${conversationId}/messages/${messageId}/`,

  MESSAGING_SEARCH: `${API_BASE}/api/messaging/search/`,

  // Ambassador Admin (scoped)
  AMBASSADOR_ADMIN_DASHBOARD: `${API_BASE}/api/ambassador/admin/dashboard/`,
  AMBASSADOR_ADMIN_TRAINERS: `${API_BASE}/api/ambassador/admin/trainers/`,
  AMBASSADOR_ADMIN_CREATE_TRAINER: `${API_BASE}/api/ambassador/admin/trainers/create/`,
  ambassadorAdminTrainerDetail: (id: number) =>
    `${API_BASE}/api/ambassador/admin/trainers/${id}/`,
  AMBASSADOR_ADMIN_SUBSCRIPTIONS: `${API_BASE}/api/ambassador/admin/subscriptions/`,
  AMBASSADOR_ADMIN_TIERS: `${API_BASE}/api/ambassador/admin/tiers/`,
  AMBASSADOR_ADMIN_COUPONS: `${API_BASE}/api/ambassador/admin/coupons/`,
  ambassadorAdminCouponDetail: (id: number) =>
    `${API_BASE}/api/ambassador/admin/coupons/${id}/`,
  ambassadorAdminImpersonate: (trainerId: number) =>
    `${API_BASE}/api/ambassador/admin/impersonate/${trainerId}/`,

  // Ambassador (self-service)
  AMBASSADOR_DASHBOARD: `${API_BASE}/api/ambassador/dashboard/`,
  AMBASSADOR_REFERRAL_CODE: `${API_BASE}/api/ambassador/referral-code/`,
  AMBASSADOR_REFERRALS: `${API_BASE}/api/ambassador/referrals/`,
  AMBASSADOR_PAYOUTS: `${API_BASE}/api/ambassador/payouts/`,
  AMBASSADOR_CONNECT_STATUS: `${API_BASE}/api/ambassador/connect/status/`,
  AMBASSADOR_CONNECT_ONBOARD: `${API_BASE}/api/ambassador/connect/onboard/`,
  AMBASSADOR_CONNECT_RETURN: `${API_BASE}/api/ambassador/connect/return/`,

  // Trainee-facing APIs (used by trainee dashboard and trainer impersonation)
  TRAINEE_PROGRAMS: `${API_BASE}/api/workouts/programs/`,
  TRAINEE_NUTRITION_SUMMARY: `${API_BASE}/api/workouts/daily-logs/nutrition-summary/`,
  TRAINEE_WEIGHT_CHECKINS: `${API_BASE}/api/workouts/weight-checkins/`,
  TRAINEE_WEIGHT_CHECKINS_LATEST: `${API_BASE}/api/workouts/weight-checkins/latest/`,
  TRAINEE_WEEKLY_PROGRESS: `${API_BASE}/api/workouts/daily-logs/weekly-progress/`,
  TRAINEE_WORKOUT_SUMMARY: `${API_BASE}/api/workouts/daily-logs/workout-summary/`,

  // Trainee community APIs
  TRAINEE_ANNOUNCEMENTS: `${API_BASE}/api/community/announcements/`,
  TRAINEE_ANNOUNCEMENTS_UNREAD: `${API_BASE}/api/community/announcements/unread-count/`,
  TRAINEE_ANNOUNCEMENTS_MARK_READ: `${API_BASE}/api/community/announcements/mark-read/`,
  traineeAnnouncementMarkRead: (id: number) =>
    `${API_BASE}/api/community/announcements/${id}/mark-read/`,
  TRAINEE_ACHIEVEMENTS: `${API_BASE}/api/community/achievements/`,

  // Trainee branding
  TRAINEE_BRANDING: `${API_BASE}/api/users/my-branding/`,

  // Macro Presets
  MACRO_PRESETS: `${API_BASE}/api/workouts/macro-presets/`,
  macroPresetDetail: (id: number) =>
    `${API_BASE}/api/workouts/macro-presets/${id}/`,
  macroPresetCopyTo: (id: number) =>
    `${API_BASE}/api/workouts/macro-presets/${id}/copy_to/`,
  MACRO_PRESETS_ALL: `${API_BASE}/api/workouts/macro-presets/all_presets/`,

  // Trainee workout/daily-log APIs
  TRAINEE_DAILY_LOGS: `${API_BASE}/api/workouts/daily-logs/`,
  TRAINEE_WORKOUT_HISTORY: `${API_BASE}/api/workouts/daily-logs/workout-history/`,
  traineeWorkoutDetail: (id: number) =>
    `${API_BASE}/api/workouts/daily-logs/${id}/workout-detail/`,

  // WebSocket
  wsMessaging: (conversationId: number) =>
    `${WS_BASE}/ws/messaging/${conversationId}/`,
} as const;

export const TOKEN_KEYS = {
  ACCESS: "fitnessai_access_token",
  REFRESH: "fitnessai_refresh_token",
} as const;

export const SESSION_COOKIE = "has_session";
export const ROLE_COOKIE = "user_role";
