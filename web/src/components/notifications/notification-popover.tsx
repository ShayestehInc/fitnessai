"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  PopoverContent,
} from "@/components/ui/popover";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import { useNotifications, useMarkAsRead } from "@/hooks/use-notifications";
import { NotificationItem, getNotificationTraineeId } from "./notification-item";
import { Loader2 } from "lucide-react";

interface NotificationPopoverProps {
  onClose: () => void;
}

export function NotificationPopover({ onClose }: NotificationPopoverProps) {
  const router = useRouter();
  const { data, isLoading, isError, refetch } = useNotifications();
  const markAsRead = useMarkAsRead();

  const notifications = data?.results?.slice(0, 5) ?? [];

  const handleNotificationClick = (n: (typeof notifications)[number]) => {
    if (!n.is_read) markAsRead.mutate(n.id);

    const traineeId = getNotificationTraineeId(n);
    if (traineeId !== null) {
      onClose();
      router.push(`/trainees/${traineeId}`);
    }
  };

  return (
    <PopoverContent align="end" className="w-80 p-0">
      <div className="flex items-center justify-between px-4 py-3">
        <h4 className="text-sm font-semibold">Notifications</h4>
      </div>
      <Separator />
      {isLoading ? (
        <div className="flex items-center justify-center py-8">
          <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
        </div>
      ) : isError ? (
        <div className="flex flex-col items-center gap-2 py-8">
          <p className="text-sm text-destructive">Failed to load</p>
          <Button variant="ghost" size="sm" onClick={() => refetch()}>
            Try again
          </Button>
        </div>
      ) : notifications.length === 0 ? (
        <p className="py-8 text-center text-sm text-muted-foreground">
          No notifications yet
        </p>
      ) : (
        <ScrollArea className="max-h-[300px]">
          <div className="space-y-1 p-2">
            {notifications.map((n) => (
              <NotificationItem
                key={n.id}
                notification={n}
                onClick={() => handleNotificationClick(n)}
              />
            ))}
          </div>
        </ScrollArea>
      )}
      <Separator />
      <div className="p-2">
        <Button
          variant="ghost"
          size="sm"
          className="w-full"
          asChild
          onClick={onClose}
        >
          <Link href="/notifications">View all notifications</Link>
        </Button>
      </div>
    </PopoverContent>
  );
}
