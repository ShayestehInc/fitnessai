"use client";

import { Menu } from "lucide-react";
import { Button } from "@/components/ui/button";
import { UserNav } from "@/components/layout/user-nav";

interface TraineeHeaderProps {
  onMenuClick: () => void;
}

export function TraineeHeader({ onMenuClick }: TraineeHeaderProps) {
  return (
    <header className="flex h-16 items-center justify-between border-b bg-background px-4 lg:px-6">
      <Button
        variant="ghost"
        size="icon"
        className="lg:hidden"
        onClick={onMenuClick}
        aria-label="Toggle menu"
      >
        <Menu className="h-5 w-5" />
      </Button>
      <div className="flex-1" />
      <div className="flex items-center gap-3">
        <UserNav />
      </div>
    </header>
  );
}
