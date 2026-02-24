"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { useTraineeBadgeCounts, getBadgeCount } from "@/hooks/use-trainee-badge-counts";
import { useTraineeBranding, getBrandingDisplayName, hasCustomPrimaryColor } from "@/hooks/use-trainee-branding";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { BrandLogo } from "./brand-logo";
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
              <BrandLogo logoUrl={branding.logo_url} altText={`${displayName} logo`} />
              <SheetTitle
                className="truncate text-lg font-semibold"
                title={displayName.length > 15 ? displayName : undefined}
              >
                {displayName}
              </SheetTitle>
            </>
          )}
        </SheetHeader>
        <SheetDescription className="sr-only">Navigation menu</SheetDescription>
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
                  className="h-4 w-4 shrink-0"
                  aria-hidden="true"
                  style={
                    isActive && isCustomColor
                      ? { color: branding.primary_color }
                      : undefined
                  }
                />
                <span className="flex-1 truncate">{link.label}</span>
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
