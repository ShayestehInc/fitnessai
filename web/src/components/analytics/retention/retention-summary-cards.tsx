"use client";

import { AlertTriangle, Heart, TrendingDown, Users } from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import type { RetentionSummary } from "@/types/retention";

interface RetentionSummaryCardsProps {
  summary: RetentionSummary;
}

export function RetentionSummaryCards({ summary }: RetentionSummaryCardsProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="At-Risk Trainees"
        value={summary.at_risk_count}
        description={`${summary.critical_count} critical, ${summary.high_count} high`}
        icon={AlertTriangle}
        valueClassName={summary.at_risk_count > 0 ? "text-orange-500" : ""}
      />
      <StatCard
        title="Avg Engagement"
        value={`${summary.avg_engagement}%`}
        description="14-day rolling average"
        icon={Heart}
      />
      <StatCard
        title="Retention Rate"
        value={`${summary.retention_rate}%`}
        description={`${summary.total_trainees - summary.at_risk_count} of ${summary.total_trainees} trainees engaged`}
        icon={Users}
        valueClassName={summary.retention_rate >= 80 ? "text-green-500" : ""}
      />
      <StatCard
        title="Critical Risk"
        value={summary.critical_count}
        description="Immediate attention needed"
        icon={TrendingDown}
        valueClassName={summary.critical_count > 0 ? "text-red-500" : ""}
      />
    </div>
  );
}
