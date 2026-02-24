"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Dumbbell, PanelLeftClose, PanelLeftOpen } from "lucide-react";
import { cn } from "@/lib/utils";
import { useMessagingUnreadCount } from "@/hooks/use-messaging";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { navGroups } from "./nav-links";

interface SidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

export function Sidebar({ collapsed, onToggle }: SidebarProps) {
  const pathname = usePathname();
  const { data: unreadData } = useMessagingUnreadCount();
  const unreadCount = unreadData?.unread_count ?? 0;

  return (
    <aside
      className={cn(
        "hidden shrink-0 border-r bg-sidebar transition-[width] duration-200 lg:block",
        collapsed ? "w-16" : "w-64",
      )}
    >
      <div className="flex h-full flex-col">
        <div
          className={cn(
            "flex h-16 items-center border-b",
            collapsed ? "justify-center px-2" : "gap-2 pl-6 pr-2",
          )}
        >
          <Dumbbell className="h-6 w-6 shrink-0 text-sidebar-primary" aria-hidden="true" />
          {!collapsed && (
            <>
              <span className="flex-1 text-lg font-semibold text-sidebar-foreground">
                FitnessAI
              </span>
              <Button
                variant="ghost"
                size="icon-sm"
                onClick={onToggle}
                className="text-sidebar-foreground/50 hover:text-sidebar-foreground"
                aria-label="Minimize sidebar"
              >
                <PanelLeftClose className="h-4 w-4" />
              </Button>
            </>
          )}
        </div>
        <TooltipProvider delayDuration={0}>
          <nav
            className={cn(
              "flex-1 overflow-y-auto py-4",
              collapsed ? "px-2" : "px-3",
            )}
            aria-label="Main navigation"
          >
            {collapsed && (
              <div className="mb-2 flex justify-center">
                <Button
                  variant="ghost"
                  size="icon-xs"
                  onClick={onToggle}
                  className="text-sidebar-foreground/50 hover:text-sidebar-foreground"
                  aria-label="Expand sidebar"
                >
                  <PanelLeftOpen className="h-4 w-4" />
                </Button>
              </div>
            )}
            {navGroups.map((group, groupIndex) => (
              <div key={group.label ?? groupIndex}>
                {group.label && !collapsed && (
                  <div className={cn("pb-1", groupIndex === 0 ? "pt-0" : "pt-4")}>
                    <span className="px-3 text-xs font-semibold uppercase tracking-wider text-sidebar-foreground/50">
                      {group.label}
                    </span>
                  </div>
                )}
                {group.label && collapsed && groupIndex > 0 && (
                  <div className="my-2 border-t border-sidebar-foreground/10" />
                )}
                <div className="space-y-1">
                  {group.links.map((link) => {
                    const isActive =
                      pathname === link.href ||
                      (link.href !== "/dashboard" && pathname.startsWith(link.href));
                    const isMessagesLink = link.href === "/messages";
                    const showBadge = isMessagesLink && unreadCount > 0;

                    const linkContent = (
                      <Link
                        key={link.href}
                        href={link.href}
                        aria-current={isActive ? "page" : undefined}
                        className={cn(
                          "flex items-center rounded-md text-sm font-medium transition-colors",
                          collapsed
                            ? "justify-center px-2 py-2"
                            : "gap-3 px-3 py-2",
                          isActive
                            ? "bg-sidebar-accent text-sidebar-accent-foreground"
                            : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-accent-foreground",
                        )}
                      >
                        <span className="relative shrink-0">
                          <link.icon className="h-4 w-4" aria-hidden="true" />
                          {collapsed && showBadge && (
                            <span className="absolute -right-1 -top-1 h-2 w-2 rounded-full bg-destructive" />
                          )}
                        </span>
                        {!collapsed && (
                          <>
                            <span className="flex-1 truncate">{link.label}</span>
                            {showBadge && (
                              <Badge
                                variant="destructive"
                                className="h-5 min-w-[20px] px-1.5 text-[10px]"
                              >
                                {unreadCount > 99 ? "99+" : unreadCount}
                              </Badge>
                            )}
                          </>
                        )}
                      </Link>
                    );

                    if (collapsed) {
                      return (
                        <Tooltip key={link.href}>
                          <TooltipTrigger asChild>{linkContent}</TooltipTrigger>
                          <TooltipContent side="right" sideOffset={8}>
                            {link.label}
                            {showBadge && ` (${unreadCount})`}
                          </TooltipContent>
                        </Tooltip>
                      );
                    }

                    return linkContent;
                  })}
                </div>
              </div>
            ))}
          </nav>
        </TooltipProvider>
      </div>
    </aside>
  );
}
