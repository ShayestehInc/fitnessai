"use client";

import Link from "next/link";
import {
  PopoverContent,
} from "@/components/ui/popover";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import { useNotifications, useMarkAsRead } from "@/hooks/use-notifications";
import { NotificationItem } from "./notification-item";
import { Loader2 } from "lucide-react";

export function NotificationPopover() {
  const { data, isLoading } = useNotifications();
  const markAsRead = useMarkAsRead();

  const notifications = data?.results?.slice(0, 5) ?? [];

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
                onClick={() => {
                  if (!n.is_read) markAsRead.mutate(n.id);
                }}
              />
            ))}
          </div>
        </ScrollArea>
      )}
      <Separator />
      <div className="p-2">
        <Button variant="ghost" size="sm" className="w-full" asChild>
          <Link href="/notifications">View all notifications</Link>
        </Button>
      </div>
    </PopoverContent>
  );
}
