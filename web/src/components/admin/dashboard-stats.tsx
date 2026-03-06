"use client";

import { Users, UserCheck, UserPlus, DollarSign } from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import { formatCurrency } from "@/lib/format-utils";
import type { AdminDashboardStats } from "@/types/admin";
import { useLocale } from "@/providers/locale-provider";

interface DashboardStatsProps {
  stats: AdminDashboardStats;
}

export function DashboardStats({ stats }: DashboardStatsProps) {
  const { t } = useLocale();
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="Total Trainers"
        value={stats.total_trainers}
        description={`${stats.active_trainers} currently active`}
        icon={Users}
      />
      <StatCard
        title={t("admin.activeTrainers")}
        value={stats.active_trainers}
        description={`${stats.total_trainers - stats.active_trainers} inactive`}
        icon={UserCheck}
      />
      <StatCard
        title={t("dashboard.totalTrainees")}
        value={stats.total_trainees}
        description={t("admin.acrossAllTrainers")}
        icon={UserPlus}
      />
      <StatCard
        title={t("admin.mrrFull")}
        value={formatCurrency(stats.monthly_recurring_revenue)}
        description="Active subscriptions"
        icon={DollarSign}
      />
    </div>
  );
}
