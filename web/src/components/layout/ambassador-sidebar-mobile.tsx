"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Handshake } from "lucide-react";
import { cn } from "@/lib/utils";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { ambassadorNavLinks, ambassadorManageLinks } from "./ambassador-nav-links";

interface AmbassadorSidebarMobileProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function AmbassadorSidebarMobile({
  open,
  onOpenChange,
}: AmbassadorSidebarMobileProps) {
  const pathname = usePathname();

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="left" className="w-64 p-0">
        <SheetHeader className="flex h-16 flex-row items-center gap-2 border-b px-6">
          <Handshake className="h-6 w-6 text-sidebar-primary" aria-hidden="true" />
          <SheetTitle className="text-lg font-semibold">Ambassador</SheetTitle>
        </SheetHeader>
        <nav className="overflow-y-auto space-y-1 px-3 py-4" aria-label="Ambassador navigation">
          {ambassadorNavLinks.map((link) => {
            const isActive =
              pathname === link.href ||
              (link.href !== "/ambassador/dashboard" &&
                pathname.startsWith(link.href));
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
              >
                <link.icon className="h-4 w-4" aria-hidden="true" />
                {link.label}
              </Link>
            );
          })}

          <div className="pb-1 pt-4">
            <span className="px-3 text-xs font-semibold uppercase tracking-wider text-sidebar-foreground/50">
              Manage
            </span>
          </div>
          {ambassadorManageLinks.map((link) => {
            const isActive =
              pathname === link.href ||
              (link.href !== "/ambassador/manage" &&
                pathname.startsWith(link.href));
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
              >
                <link.icon className="h-4 w-4" aria-hidden="true" />
                {link.label}
              </Link>
            );
          })}
        </nav>
      </SheetContent>
    </Sheet>
  );
}
