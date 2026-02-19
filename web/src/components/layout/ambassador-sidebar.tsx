"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Handshake } from "lucide-react";
import { cn } from "@/lib/utils";
import { ambassadorNavLinks } from "./ambassador-nav-links";

export function AmbassadorSidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden w-64 shrink-0 border-r bg-sidebar lg:block">
      <div className="flex h-full flex-col">
        <div className="flex h-16 items-center gap-2 border-b px-6">
          <Handshake className="h-6 w-6 text-sidebar-primary" aria-hidden="true" />
          <span className="text-lg font-semibold text-sidebar-foreground">
            Ambassador
          </span>
        </div>
        <nav className="flex-1 space-y-1 px-3 py-4" aria-label="Ambassador navigation">
          {ambassadorNavLinks.map((link) => {
            const isActive =
              pathname === link.href ||
              (link.href !== "/ambassador/dashboard" &&
                pathname.startsWith(link.href));
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
                {link.label}
              </Link>
            );
          })}
        </nav>
      </div>
    </aside>
  );
}
