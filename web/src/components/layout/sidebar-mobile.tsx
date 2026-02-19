"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Dumbbell } from "lucide-react";
import { cn } from "@/lib/utils";
import { useMessagingUnreadCount } from "@/hooks/use-messaging";
import { Badge } from "@/components/ui/badge";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { navLinks } from "./nav-links";

interface SidebarMobileProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function SidebarMobile({ open, onOpenChange }: SidebarMobileProps) {
  const pathname = usePathname();
  const { data: unreadData } = useMessagingUnreadCount();
  const unreadCount = unreadData?.unread_count ?? 0;

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="left" className="w-64 p-0">
        <SheetHeader className="flex h-16 flex-row items-center gap-2 border-b px-6">
          <Dumbbell className="h-6 w-6 text-primary" aria-hidden="true" />
          <SheetTitle className="text-lg font-semibold">FitnessAI</SheetTitle>
        </SheetHeader>
        <nav className="space-y-1 px-3 py-4" aria-label="Main navigation">
          {navLinks.map((link) => {
            const isActive =
              pathname === link.href ||
              (link.href !== "/dashboard" && pathname.startsWith(link.href));
            const isMessagesLink = link.href === "/messages";
            return (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => onOpenChange(false)}
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                  isActive
                    ? "bg-accent text-accent-foreground"
                    : "text-muted-foreground hover:bg-accent/50 hover:text-accent-foreground",
                )}
              >
                <link.icon className="h-4 w-4" aria-hidden="true" />
                <span className="flex-1">{link.label}</span>
                {isMessagesLink && unreadCount > 0 && (
                  <Badge
                    variant="destructive"
                    className="h-5 min-w-[20px] px-1.5 text-[10px]"
                  >
                    {unreadCount > 99 ? "99+" : unreadCount}
                  </Badge>
                )}
              </Link>
            );
          })}
        </nav>
      </SheetContent>
    </Sheet>
  );
}
