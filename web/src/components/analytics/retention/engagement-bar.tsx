"use client";

import { cn } from "@/lib/utils";

interface EngagementBarProps {
  value: number;
  className?: string;
}

function getBarColor(value: number): string {
  if (value >= 75) return "hsl(142, 71%, 45%)";
  if (value >= 50) return "hsl(45, 93%, 47%)";
  if (value >= 25) return "hsl(25, 95%, 53%)";
  return "hsl(0, 84%, 60%)";
}

export function EngagementBar({ value, className }: EngagementBarProps) {
  const clamped = Math.max(0, Math.min(100, value));

  return (
    <div className={cn("flex items-center gap-2", className)}>
      <div
        className="relative h-2 w-20 overflow-hidden rounded-full bg-primary/20"
        role="progressbar"
        aria-valuenow={clamped}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div
          className="h-full rounded-full transition-all duration-300"
          style={{
            width: `${clamped}%`,
            backgroundColor: getBarColor(clamped),
          }}
        />
      </div>
      <span className="text-xs tabular-nums text-muted-foreground">
        {clamped.toFixed(0)}
      </span>
    </div>
  );
}
