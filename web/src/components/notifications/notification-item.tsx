import { formatDistanceToNow } from "date-fns";
import { cn } from "@/lib/utils";
import { UserPlus, Dumbbell, Utensils, AlertTriangle, Info } from "lucide-react";
import type { Notification } from "@/types/notification";

const iconMap: Record<string, typeof UserPlus> = {
  trainee_joined: UserPlus,
  trainee_completed_onboarding: UserPlus,
  trainee_logged_workout: Dumbbell,
  trainee_logged_food: Utensils,
  trainee_inactive: AlertTriangle,
  system: Info,
};

interface NotificationItemProps {
  notification: Notification;
  onClick?: () => void;
}

export function NotificationItem({
  notification,
  onClick,
}: NotificationItemProps) {
  const Icon = iconMap[notification.notification_type] ?? Info;

  return (
    <button
      onClick={onClick}
      className={cn(
        "flex w-full items-start gap-3 rounded-md px-3 py-2 text-left transition-colors hover:bg-accent",
        !notification.is_read && "bg-accent/50",
      )}
    >
      <div className="mt-0.5 shrink-0">
        <Icon className="h-4 w-4 text-muted-foreground" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <p
            className={cn(
              "truncate text-sm",
              !notification.is_read && "font-medium",
            )}
          >
            {notification.title}
          </p>
          {!notification.is_read && (
            <span className="h-2 w-2 shrink-0 rounded-full bg-primary" />
          )}
        </div>
        <p className="truncate text-xs text-muted-foreground">
          {notification.message}
        </p>
        <p className="mt-0.5 text-xs text-muted-foreground">
          {formatDistanceToNow(new Date(notification.created_at), {
            addSuffix: true,
          })}
        </p>
      </div>
    </button>
  );
}
