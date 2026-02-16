"use client";

import { useRef, useCallback } from "react";
import type { AdherencePeriod } from "@/types/analytics";

const PERIODS: AdherencePeriod[] = [7, 14, 30];

interface PeriodSelectorProps {
  value: AdherencePeriod;
  onChange: (days: AdherencePeriod) => void;
}

export function PeriodSelector({ value, onChange }: PeriodSelectorProps) {
  const groupRef = useRef<HTMLDivElement>(null);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
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
    [value, onChange],
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
            tabIndex={isActive ? 0 : -1}
            onClick={() => onChange(days)}
            className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
              isActive
                ? "bg-primary text-primary-foreground"
                : "bg-muted text-muted-foreground hover:bg-muted/80"
            }`}
          >
            {days}d
          </button>
        );
      })}
    </div>
  );
}
