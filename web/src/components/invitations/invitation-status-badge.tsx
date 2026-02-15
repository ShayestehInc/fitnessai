import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import type { InvitationStatus } from "@/types/invitation";

const statusConfig: Record<
  string,
  { label: string; className: string }
> = {
  PENDING: {
    label: "Pending",
    className:
      "border-amber-500/50 bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-400",
  },
  ACCEPTED: {
    label: "Accepted",
    className:
      "border-green-500/50 bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-400",
  },
  EXPIRED: {
    label: "Expired",
    className:
      "border-muted bg-muted text-muted-foreground",
  },
  CANCELLED: {
    label: "Cancelled",
    className:
      "border-red-500/50 bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-400",
  },
};

interface InvitationStatusBadgeProps {
  status: InvitationStatus;
  isExpired?: boolean;
}

export function InvitationStatusBadge({
  status,
  isExpired,
}: InvitationStatusBadgeProps) {
  const effectiveStatus = isExpired && status === "PENDING" ? "EXPIRED" : status;
  const config = statusConfig[effectiveStatus] ?? statusConfig.PENDING;

  return (
    <Badge variant="outline" className={cn("text-xs", config.className)}>
      {config.label}
    </Badge>
  );
}
