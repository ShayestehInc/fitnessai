"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { RISK_TIER_COLORS } from "@/lib/chart-utils";
import type { RetentionSummary } from "@/types/retention";
import { useLocale } from "@/providers/locale-provider";

interface RiskDistributionChartProps {
  summary: RetentionSummary;
}

const SEGMENTS: { key: keyof typeof RISK_TIER_COLORS; label: string }[] = [
  { key: "critical", label: "Critical" },
  { key: "high", label: "High" },
  { key: "medium", label: "Medium" },
  { key: "low", label: "Low" },
];

export function RiskDistributionChart({
  summary,
}: RiskDistributionChartProps) {
  const { t } = useLocale();
  const total = summary.total_trainees;
  if (total === 0) return null;

  const counts: Record<string, number> = {
    critical: summary.critical_count,
    high: summary.high_count,
    medium: summary.medium_count,
    low: summary.low_count,
  };

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-base">{t("analytics.riskDistribution")}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {/* Stacked bar */}
        <div
          className="flex h-6 w-full overflow-hidden rounded-full"
          role="img"
          aria-label="Risk distribution chart"
        >
          {SEGMENTS.map(({ key }) => {
            const pct = (counts[key] / total) * 100;
            if (pct === 0) return null;
            return (
              <div
                key={key}
                className="transition-all duration-300"
                style={{
                  width: `${pct}%`,
                  backgroundColor: RISK_TIER_COLORS[key],
                }}
                title={`${key}: ${counts[key]} (${pct.toFixed(0)}%)`}
              />
            );
          })}
        </div>

        {/* Legend */}
        <div className="flex flex-wrap gap-x-4 gap-y-1">
          {SEGMENTS.map(({ key, label }) => (
            <div key={key} className="flex items-center gap-1.5 text-sm">
              <div
                className="h-2.5 w-2.5 rounded-full"
                style={{ backgroundColor: RISK_TIER_COLORS[key] }}
              />
              <span className="text-muted-foreground">
                {label}: {counts[key]}
              </span>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
