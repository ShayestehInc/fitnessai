"use client";

const PERIODS = [7, 14, 30] as const;

interface PeriodSelectorProps {
  value: number;
  onChange: (days: number) => void;
}

export function PeriodSelector({ value, onChange }: PeriodSelectorProps) {
  return (
    <div className="flex gap-1" role="radiogroup" aria-label="Time period">
      {PERIODS.map((days) => {
        const isActive = value === days;
        return (
          <button
            key={days}
            type="button"
            role="radio"
            aria-checked={isActive}
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
