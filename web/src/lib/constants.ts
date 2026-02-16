const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

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
  ANALYTICS_PROGRESS: `${API_BASE}/api/trainer/analytics/progress/`,

  // Programs & Exercises
  PROGRAM_TEMPLATES: `${API_BASE}/api/trainer/program-templates/`,
  programTemplateDetail: (id: number) =>
    `${API_BASE}/api/trainer/program-templates/${id}/`,
  programTemplateAssign: (id: number) =>
    `${API_BASE}/api/trainer/program-templates/${id}/assign/`,
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
} as const;

export const TOKEN_KEYS = {
  ACCESS: "fitnessai_access_token",
  REFRESH: "fitnessai_refresh_token",
} as const;

export const SESSION_COOKIE = "has_session";
