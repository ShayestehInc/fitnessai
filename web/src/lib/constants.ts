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
} as const;

export const TOKEN_KEYS = {
  ACCESS: "fitnessai_access_token",
  REFRESH: "fitnessai_refresh_token",
} as const;

export const SESSION_COOKIE = "has_session";
