"use client";

import { useState, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useRetentionAnalytics } from "@/hooks/use-analytics";
import { RetentionSummaryCards } from "./retention-summary-cards";
import { RiskDistributionChart } from "./risk-distribution-chart";
import { RetentionTrendChart } from "./retention-trend-chart";
import { AtRiskTraineeTable } from "./at-risk-trainee-table";
import type { RetentionPeriod, TraineeEngagement } from "@/types/retention";
import { useLocale } from "@/providers/locale-provider";

const PERIODS: RetentionPeriod[] = [7, 14, 30];

function RetentionPeriodSelector({
  value,
  onChange,
  disabled,
}: {
  value: RetentionPeriod;
  onChange: (v: RetentionPeriod) => void;
  disabled?: boolean;
}) {
  const groupRef = useRef<HTMLDivElement>(null);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (disabled) return;
      const idx = PERIODS.indexOf(value);
      let next = idx;
      if (e.key === "ArrowRight" || e.key === "ArrowDown") {
        e.preventDefault();
        next = (idx + 1) % PERIODS.length;
      } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
        e.preventDefault();
        next = (idx - 1 + PERIODS.length) % PERIODS.length;
      } else {
        return;
      }
      onChange(PERIODS[next]);
      groupRef.current
        ?.querySelectorAll<HTMLButtonElement>('[role="radio"]')
        ?.[next]?.focus();
    },
    [value, onChange, disabled],
  );

  return (
    <div
      ref={groupRef}
      className="flex gap-1"
      role="radiogroup"
      aria-label="Retention period"
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
            aria-label={`${days} days`}
            tabIndex={isActive ? 0 : -1}
            disabled={disabled}
            onClick={() => onChange(days)}
            className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:pointer-events-none disabled:opacity-50 ${
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

function RetentionSkeleton() {
  return (
    <div className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <Card key={i} className="p-6">
            <Skeleton className="mb-2 h-4 w-24" />
            <Skeleton className="h-8 w-16" />
          </Card>
        ))}
      </div>
      <Card className="p-6">
        <Skeleton className="h-[240px] w-full" />
      </Card>
    </div>
  );
}

export function RetentionSection() {
  const { t } = useLocale();
  const [days, setDays] = useState<RetentionPeriod>(14);
  const { data, isLoading, isFetching } = useRetentionAnalytics(days);
  const router = useRouter();

  const handleRowClick = useCallback(
    (trainee: TraineeEngagement) => {
      router.push(`/trainees/${trainee.trainee_id}`);
    },
    [router],
  );

  if (isLoading) {
    return (
      <section aria-label={t("trainer.retentionAnalytics")}>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold">Retention & Churn Risk</h2>
          <RetentionPeriodSelector
            value={days}
            onChange={setDays}
            disabled
          />
        </div>
        <RetentionSkeleton />
      </section>
    );
  }

  if (!data || data.summary.total_trainees === 0) {
    return (
      <section aria-label={t("trainer.retentionAnalytics")}>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold">Retention & Churn Risk</h2>
          <RetentionPeriodSelector value={days} onChange={setDays} />
        </div>
        <Card className="flex flex-col items-center justify-center p-8 text-center">
          <p className="text-muted-foreground">
            No trainee data available. Invite trainees to see retention
            analytics.
          </p>
        </Card>
      </section>
    );
  }

  return (
    <section aria-label={t("trainer.retentionAnalytics")}>
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-lg font-semibold">Retention & Churn Risk</h2>
        <RetentionPeriodSelector
          value={days}
          onChange={setDays}
          disabled={isFetching}
        />
      </div>
      <div
        className="space-y-4 transition-opacity duration-200"
        style={{ opacity: isFetching ? 0.5 : 1 }}
      >
        <RetentionSummaryCards summary={data.summary} />
        <div className="grid gap-4 lg:grid-cols-2">
          <RiskDistributionChart summary={data.summary} />
          <RetentionTrendChart trends={data.trends} />
        </div>
        <AtRiskTraineeTable
          trainees={data.trainees}
          onRowClick={handleRowClick}
        />
      </div>
    </section>
  );
}
