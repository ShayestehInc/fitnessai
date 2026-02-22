"use client";

import { Menu } from "lucide-react";
import { Button } from "@/components/ui/button";
import { UserNav } from "@/components/layout/user-nav";
import { useAuth } from "@/hooks/use-auth";

interface TraineeHeaderProps {
  onMenuClick: () => void;
}

export function TraineeHeader({ onMenuClick }: TraineeHeaderProps) {
  const { user } = useAuth();
  const displayName = user
    ? [user.first_name, user.last_name].filter(Boolean).join(" ") || user.email
    : "";

  return (
    <header className="flex h-16 items-center justify-between border-b bg-background px-4 lg:px-6">
      <div className="flex items-center gap-3">
        <Button
          variant="ghost"
          size="icon"
          className="lg:hidden"
          onClick={onMenuClick}
          aria-label="Toggle menu"
        >
          <Menu className="h-5 w-5" />
        </Button>
        {displayName && (
          <span className="text-sm font-medium text-foreground">
            {displayName}
          </span>
        )}
      </div>
      <div className="flex items-center gap-3">
        <UserNav />
      </div>
    </header>
  );
}
