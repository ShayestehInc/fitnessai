"use client";

import { AlertTriangle, Heart, TrendingDown, Users } from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import type { RetentionSummary } from "@/types/retention";
import { useLocale } from "@/providers/locale-provider";

interface RetentionSummaryCardsProps {
  summary: RetentionSummary;
}

export function RetentionSummaryCards({ summary }: RetentionSummaryCardsProps) {
  const { t } = useLocale();
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title={t("trainer.atRiskTrainees")}
        value={summary.at_risk_count}
        description={`${summary.critical_count} critical, ${summary.high_count} high`}
        icon={AlertTriangle}
        valueClassName={summary.at_risk_count > 0 ? "text-orange-500" : ""}
      />
      <StatCard
        title={t("analytics.avgEngagement")}
        value={`${summary.avg_engagement}%`}
        description={t("traineeView.rollingAvg")}
        icon={Heart}
      />
      <StatCard
        title={t("analytics.retentionRate")}
        value={`${summary.retention_rate}%`}
        description={`${summary.total_trainees - summary.at_risk_count} of ${summary.total_trainees} trainees engaged`}
        icon={Users}
        valueClassName={summary.retention_rate >= 80 ? "text-green-500" : ""}
      />
      <StatCard
        title={t("analytics.criticalRisk")}
        value={summary.critical_count}
        description="Immediate attention needed"
        icon={TrendingDown}
        valueClassName={summary.critical_count > 0 ? "text-red-500" : ""}
      />
    </div>
  );
}
