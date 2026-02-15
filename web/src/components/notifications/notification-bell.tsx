"use client";

import { useState } from "react";
import { Bell } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Popover, PopoverTrigger } from "@/components/ui/popover";
import { useUnreadCount } from "@/hooks/use-notifications";
import { NotificationPopover } from "./notification-popover";

export function NotificationBell() {
  const { data } = useUnreadCount();
  const count = data?.unread_count ?? 0;
  const [open, setOpen] = useState(false);

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-5 w-5" />
          {count > 0 && (
            <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-destructive px-1 text-[10px] font-medium text-destructive-foreground">
              {count > 99 ? "99+" : count}
            </span>
          )}
          <span className="sr-only">
            {count > 0 ? `${count} unread notifications` : "Notifications"}
          </span>
        </Button>
      </PopoverTrigger>
      <NotificationPopover onClose={() => setOpen(false)} />
    </Popover>
  );
}
