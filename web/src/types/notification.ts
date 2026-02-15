export const NotificationType = {
  TRAINEE_JOINED: "trainee_joined",
  TRAINEE_COMPLETED_ONBOARDING: "trainee_completed_onboarding",
  TRAINEE_LOGGED_WORKOUT: "trainee_logged_workout",
  TRAINEE_LOGGED_FOOD: "trainee_logged_food",
  TRAINEE_INACTIVE: "trainee_inactive",
  SYSTEM: "system",
} as const;

export type NotificationType =
  (typeof NotificationType)[keyof typeof NotificationType];

export interface Notification {
  id: number;
  notification_type: NotificationType;
  title: string;
  message: string;
  is_read: boolean;
  trainee: number | null;
  created_at: string;
}

export interface UnreadCount {
  unread_count: number;
}
