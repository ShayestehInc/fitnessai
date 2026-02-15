import { formatDistanceToNow } from "date-fns";
import { cn } from "@/lib/utils";
import type { LucideIcon } from "lucide-react";
import {
  Activity,
  Dumbbell,
  AlertTriangle,
  Target,
  ClipboardCheck,
  MessageSquare,
  Info,
  ChevronRight,
} from "lucide-react";
import type { Notification } from "@/types/notification";

const iconMap: Record<string, LucideIcon> = {
  trainee_readiness: Activity,
  workout_completed: Dumbbell,
  workout_missed: AlertTriangle,
  goal_hit: Target,
  check_in: ClipboardCheck,
  message: MessageSquare,
  general: Info,
};

export function getNotificationTraineeId(
  notification: Notification,
): number | null {
  const raw = notification.data?.trainee_id;
  if (typeof raw === "number" && raw > 0) return raw;
  if (typeof raw === "string") {
    const parsed = parseInt(raw, 10);
    if (!isNaN(parsed) && parsed > 0) return parsed;
  }
  return null;
}

interface NotificationItemProps {
  notification: Notification;
  onClick?: () => void;
}

export function NotificationItem({
  notification,
  onClick,
}: NotificationItemProps) {
  const Icon = iconMap[notification.notification_type] ?? Info;
  const navigable = getNotificationTraineeId(notification) !== null;

  const ariaLabel = `${notification.is_read ? "" : "Unread: "}${notification.title} — ${notification.message}${navigable ? ". Click to view trainee." : ""}`;

  return (
    <button
      onClick={onClick}
      aria-label={ariaLabel}
      className={cn(
        "flex w-full items-start gap-3 rounded-md px-3 py-2 text-left transition-colors hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
        !notification.is_read && "bg-accent/50",
      )}
    >
      <div className="mt-0.5 shrink-0">
        <Icon className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <p
            className={cn(
              "truncate text-sm",
              !notification.is_read && "font-medium",
            )}
            title={notification.title}
          >
            {notification.title}
          </p>
          {!notification.is_read && (
            <span className="h-2 w-2 shrink-0 rounded-full bg-primary" />
          )}
        </div>
        <p className="truncate text-xs text-muted-foreground" title={notification.message}>
          {notification.message}
        </p>
        <p className="mt-0.5 text-xs text-muted-foreground">
          {formatDistanceToNow(new Date(notification.created_at), {
            addSuffix: true,
          })}
        </p>
      </div>
      {navigable && (
        <div className="mt-0.5 shrink-0">
          <ChevronRight className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
        </div>
      )}
    </button>
  );
}
