"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Dumbbell, PanelLeftClose, PanelLeftOpen } from "lucide-react";
import { cn } from "@/lib/utils";
import { useTraineeBadgeCounts, getBadgeCount } from "@/hooks/use-trainee-badge-counts";
import { useTraineeBranding, getBrandingDisplayName } from "@/hooks/use-trainee-branding";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { traineeNavLinks } from "./trainee-nav-links";

interface TraineeSidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

function BrandLogo({
  logoUrl,
  size = "h-6 w-6",
}: {
  logoUrl: string | null;
  size?: string;
}) {
  const [imgError, setImgError] = useState(false);

  if (!logoUrl || imgError) {
    return <Dumbbell className={cn(size, "shrink-0 text-sidebar-primary")} aria-hidden="true" />;
  }

  return (
    <Image
      src={logoUrl}
      alt=""
      width={24}
      height={24}
      className={cn(size, "shrink-0 rounded object-contain")}
      onError={() => setImgError(true)}
      aria-hidden="true"
      unoptimized
    />
  );
}

export function TraineeSidebar({ collapsed, onToggle }: TraineeSidebarProps) {
  const pathname = usePathname();
  const counts = useTraineeBadgeCounts();
  const { branding, isLoading: brandingLoading } = useTraineeBranding();
  const displayName = getBrandingDisplayName(branding);

  return (
    <aside
      className={cn(
        "hidden shrink-0 border-r bg-sidebar transition-[width] duration-200 lg:block",
        collapsed ? "w-16" : "w-64",
      )}
      style={
        branding.primary_color !== "#6366F1"
          ? ({ "--sidebar-accent-brand": branding.primary_color } as React.CSSProperties)
          : undefined
      }
    >
      <div className="flex h-full flex-col">
        <div
          className={cn(
            "flex h-16 items-center border-b",
            collapsed ? "justify-center px-2" : "gap-2 pl-6 pr-2",
          )}
        >
          {brandingLoading ? (
            <>
              <Skeleton className="h-6 w-6 shrink-0 rounded" />
              {!collapsed && <Skeleton className="h-5 w-24" />}
            </>
          ) : (
            <>
              <BrandLogo logoUrl={branding.logo_url} />
              {!collapsed && (
                <>
                  <span
                    className="flex-1 truncate text-lg font-semibold text-sidebar-foreground"
                    title={displayName.length > 15 ? displayName : undefined}
                  >
                    {displayName}
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
            </>
          )}
        </div>
        <TooltipProvider delayDuration={0}>
          <nav
            className={cn(
              "flex-1 overflow-y-auto space-y-1 py-4",
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
            {traineeNavLinks.map((link) => {
              const isActive =
                pathname === link.href ||
                (link.href !== "/trainee/dashboard" &&
                  pathname.startsWith(link.href));
              const badgeCount = getBadgeCount(counts, link.badgeKey);
              const showBadge = badgeCount > 0;

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
                  style={
                    isActive && branding.primary_color !== "#6366F1"
                      ? { backgroundColor: `${branding.primary_color}20` }
                      : undefined
                  }
                >
                  <span className="relative shrink-0">
                    <link.icon
                      className="h-4 w-4"
                      aria-hidden="true"
                      style={
                        isActive && branding.primary_color !== "#6366F1"
                          ? { color: branding.primary_color }
                          : undefined
                      }
                    />
                    {collapsed && showBadge && (
                      <span className="absolute -right-1 -top-1 h-2 w-2 rounded-full bg-destructive" />
                    )}
                  </span>
                  {!collapsed && (
                    <>
                      <span className="flex-1">{link.label}</span>
                      {showBadge && (
                        <Badge
                          variant="destructive"
                          className="h-5 min-w-[20px] px-1.5 text-[10px]"
                        >
                          {badgeCount > 99 ? "99+" : badgeCount}
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
                      {showBadge && ` (${badgeCount})`}
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
