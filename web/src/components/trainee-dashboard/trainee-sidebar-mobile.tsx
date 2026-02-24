"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Dumbbell } from "lucide-react";
import { cn } from "@/lib/utils";
import { useTraineeBadgeCounts, getBadgeCount } from "@/hooks/use-trainee-badge-counts";
import { useTraineeBranding, getBrandingDisplayName, hasCustomPrimaryColor } from "@/hooks/use-trainee-branding";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { traineeNavLinks } from "./trainee-nav-links";

interface TraineeSidebarMobileProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function TraineeSidebarMobile({
  open,
  onOpenChange,
}: TraineeSidebarMobileProps) {
  const pathname = usePathname();
  const counts = useTraineeBadgeCounts();
  const { branding, isLoading: brandingLoading } = useTraineeBranding();
  const displayName = getBrandingDisplayName(branding);
  const isCustomColor = hasCustomPrimaryColor(branding);
  const [imgError, setImgError] = useState(false);

  const showLogo = branding.logo_url && !imgError;

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="left" className="w-64 p-0">
        <SheetHeader className="flex h-16 flex-row items-center gap-2 border-b px-6">
          {brandingLoading ? (
            <>
              <Skeleton className="h-6 w-6 rounded" />
              <Skeleton className="h-5 w-24" />
            </>
          ) : (
            <>
              {showLogo ? (
                <Image
                  src={branding.logo_url!}
                  alt=""
                  width={24}
                  height={24}
                  className="h-6 w-6 shrink-0 rounded object-contain"
                  onError={() => setImgError(true)}
                  aria-hidden="true"
                  unoptimized
                />
              ) : (
                <Dumbbell className="h-6 w-6 text-sidebar-primary" aria-hidden="true" />
              )}
              <SheetTitle className="truncate text-lg font-semibold">
                {displayName}
              </SheetTitle>
            </>
          )}
        </SheetHeader>
        <nav className="overflow-y-auto space-y-1 px-3 py-4" aria-label="Main navigation">
          {traineeNavLinks.map((link) => {
            const isActive =
              pathname === link.href ||
              (link.href !== "/trainee/dashboard" &&
                pathname.startsWith(link.href));
            const badgeCount = getBadgeCount(counts, link.badgeKey);
            return (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => onOpenChange(false)}
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                  isActive
                    ? "bg-sidebar-accent text-sidebar-accent-foreground"
                    : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-accent-foreground",
                )}
                style={
                  isActive && isCustomColor
                    ? { backgroundColor: `${branding.primary_color}20` }
                    : undefined
                }
              >
                <link.icon
                  className="h-4 w-4"
                  aria-hidden="true"
                  style={
                    isActive && isCustomColor
                      ? { color: branding.primary_color }
                      : undefined
                  }
                />
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
      </SheetContent>
    </Sheet>
  );
}
