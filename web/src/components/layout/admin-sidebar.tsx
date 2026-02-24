"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Shield, PanelLeftClose, PanelLeftOpen } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { adminNavLinks } from "./admin-nav-links";

interface AdminSidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

export function AdminSidebar({ collapsed, onToggle }: AdminSidebarProps) {
  const pathname = usePathname();

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
          <Shield className="h-6 w-6 shrink-0 text-sidebar-primary" aria-hidden="true" />
          {!collapsed && (
            <>
              <span className="flex-1 text-lg font-semibold text-sidebar-foreground">
                FitnessAI Admin
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
              "flex-1 overflow-y-auto space-y-1 py-4",
              collapsed ? "px-2" : "px-3",
            )}
            aria-label="Admin navigation"
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
            {adminNavLinks.map((link) => {
              const isActive =
                pathname === link.href ||
                (link.href !== "/admin/dashboard" &&
                  pathname.startsWith(link.href));

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
                  <link.icon className="h-4 w-4 shrink-0" aria-hidden="true" />
                  {!collapsed && <span className="truncate">{link.label}</span>}
                </Link>
              );

              if (collapsed) {
                return (
                  <Tooltip key={link.href}>
                    <TooltipTrigger asChild>{linkContent}</TooltipTrigger>
                    <TooltipContent side="right" sideOffset={8}>
                      {link.label}
                    </TooltipContent>
                  </Tooltip>
                );
              }

              return linkContent;
            })}
          </nav>
        </TooltipProvider>
      </div>
    </aside>
  );
}
