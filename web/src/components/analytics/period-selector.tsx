"use client";

import { useRef, useCallback } from "react";
import type { AdherencePeriod } from "@/types/analytics";

const PERIODS: AdherencePeriod[] = [7, 14, 30];

const PERIOD_LABELS: Record<AdherencePeriod, string> = {
  7: "7 days",
  14: "14 days",
  30: "30 days",
};

interface PeriodSelectorProps {
  value: AdherencePeriod;
  onChange: (days: AdherencePeriod) => void;
  disabled?: boolean;
}

export function PeriodSelector({ value, onChange, disabled = false }: PeriodSelectorProps) {
  const groupRef = useRef<HTMLDivElement>(null);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (disabled) return;

      const currentIndex = PERIODS.indexOf(value);
      let nextIndex = currentIndex;

      if (e.key === "ArrowRight" || e.key === "ArrowDown") {
        e.preventDefault();
        nextIndex = (currentIndex + 1) % PERIODS.length;
      } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
        e.preventDefault();
        nextIndex = (currentIndex - 1 + PERIODS.length) % PERIODS.length;
      } else {
        return;
      }

      onChange(PERIODS[nextIndex]);
      const buttons = groupRef.current?.querySelectorAll<HTMLButtonElement>(
        '[role="radio"]',
      );
      buttons?.[nextIndex]?.focus();
    },
    [value, onChange, disabled],
  );

  return (
    <div
      ref={groupRef}
      className="flex gap-1"
      role="radiogroup"
      aria-label="Time period"
      onKeyDown={handleKeyDown}
    >
      {PERIODS.map((days) => {
        const isActive = value === days;
        return (
          <button
            key={days}
            type="button"
            role="radio"
            aria-checked={isActive}
            aria-label={PERIOD_LABELS[days]}
            tabIndex={isActive ? 0 : -1}
            disabled={disabled}
            onClick={() => onChange(days)}
            className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 ${
              isActive
                ? "bg-primary text-primary-foreground active:bg-primary/90"
                : "bg-muted text-muted-foreground hover:bg-accent hover:text-accent-foreground active:bg-accent/80"
            }`}
          >
            {days}d
          </button>
        );
      })}
    </div>
  );
}
