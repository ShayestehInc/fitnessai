"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Dumbbell } from "lucide-react";
import { cn } from "@/lib/utils";
import { useMessagingUnreadCount } from "@/hooks/use-messaging";
import { useAnnouncementUnreadCount } from "@/hooks/use-trainee-announcements";
import { Badge } from "@/components/ui/badge";
import { traineeNavLinks } from "./trainee-nav-links";

export function TraineeSidebar() {
  const pathname = usePathname();
  const { data: unreadMessages } = useMessagingUnreadCount();
  const { data: unreadAnnouncements } = useAnnouncementUnreadCount();

  const messageCount = unreadMessages?.unread_count ?? 0;
  const announcementCount = unreadAnnouncements?.unread_count ?? 0;

  function getBadgeCount(badgeKey?: string): number {
    if (badgeKey === "messages") return messageCount;
    if (badgeKey === "announcements") return announcementCount;
    return 0;
  }

  return (
    <aside className="hidden w-64 shrink-0 border-r bg-sidebar lg:block">
      <div className="flex h-full flex-col">
        <div className="flex h-16 items-center gap-2 border-b px-6">
          <Dumbbell className="h-6 w-6 text-sidebar-primary" aria-hidden="true" />
          <span className="text-lg font-semibold text-sidebar-foreground">
            FitnessAI
          </span>
        </div>
        <nav className="flex-1 space-y-1 px-3 py-4" aria-label="Main navigation">
          {traineeNavLinks.map((link) => {
            const isActive =
              pathname === link.href ||
              (link.href !== "/trainee/dashboard" &&
                pathname.startsWith(link.href));
            const badgeCount = getBadgeCount(link.badgeKey);
            return (
              <Link
                key={link.href}
                href={link.href}
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                  isActive
                    ? "bg-sidebar-accent text-sidebar-accent-foreground"
                    : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-accent-foreground",
                )}
              >
                <link.icon className="h-4 w-4" aria-hidden="true" />
                <span className="flex-1">{link.label}</span>
                {badgeCount > 0 && (
                  <Badge
                    variant="destructive"
                    className="h-5 min-w-[20px] px-1.5 text-[10px]"
                  >
                    {badgeCount > 99 ? "99+" : badgeCount}
                  </Badge>
                )}
              </Link>
            );
          })}
        </nav>
      </div>
    </aside>
  );
}
