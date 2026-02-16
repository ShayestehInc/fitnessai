"use client";

import { Users, UserCheck, UserPlus, DollarSign } from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import { formatCurrency } from "@/lib/format-utils";
import type { AdminDashboardStats } from "@/types/admin";

interface DashboardStatsProps {
  stats: AdminDashboardStats;
}

export function DashboardStats({ stats }: DashboardStatsProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="Total Trainers"
        value={stats.total_trainers}
        description={`${stats.active_trainers} currently active`}
        icon={Users}
      />
      <StatCard
        title="Active Trainers"
        value={stats.active_trainers}
        description={`${stats.total_trainers - stats.active_trainers} inactive`}
        icon={UserCheck}
      />
      <StatCard
        title="Total Trainees"
        value={stats.total_trainees}
        description="Across all trainers"
        icon={UserPlus}
      />
      <StatCard
        title="Monthly Recurring Revenue"
        value={formatCurrency(stats.monthly_recurring_revenue)}
        description="Active subscriptions"
        icon={DollarSign}
      />
    </div>
  );
}
