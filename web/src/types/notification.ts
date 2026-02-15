export const NotificationType = {
  TRAINEE_READINESS: "trainee_readiness",
  WORKOUT_COMPLETED: "workout_completed",
  WORKOUT_MISSED: "workout_missed",
  GOAL_HIT: "goal_hit",
  CHECK_IN: "check_in",
  MESSAGE: "message",
  GENERAL: "general",
} as const;

export type NotificationType =
  (typeof NotificationType)[keyof typeof NotificationType];

export interface Notification {
  id: number;
  notification_type: NotificationType;
  title: string;
  message: string;
  data: Record<string, unknown>;
  is_read: boolean;
  read_at: string | null;
  created_at: string;
}

export interface UnreadCount {
  unread_count: number;
}
