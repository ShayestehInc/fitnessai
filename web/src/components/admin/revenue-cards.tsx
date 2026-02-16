"use client";

import {
  AlertTriangle,
  CalendarClock,
  CalendarDays,
  CalendarRange,
} from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import type { AdminDashboardStats } from "@/types/admin";

interface RevenueCardsProps {
  stats: AdminDashboardStats;
}

function formatCurrency(value: string): string {
  const num = parseFloat(value);
  if (isNaN(num)) return "$0.00";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(num);
}

export function RevenueCards({ stats }: RevenueCardsProps) {
  return (
    <div className="space-y-3">
      <h2 className="text-lg font-semibold">Revenue & Payments</h2>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Past Due"
          value={formatCurrency(stats.total_past_due)}
          description={`${stats.past_due_count} past due accounts`}
          icon={AlertTriangle}
          valueClassName={
            parseFloat(stats.total_past_due) > 0
              ? "text-destructive"
              : undefined
          }
        />
        <StatCard
          title="Payments Due Today"
          value={stats.payments_due_today}
          description="Active subscriptions"
          icon={CalendarClock}
        />
        <StatCard
          title="Due This Week"
          value={stats.payments_due_this_week}
          description="Next 7 days"
          icon={CalendarDays}
        />
        <StatCard
          title="Due This Month"
          value={stats.payments_due_this_month}
          description="Next 30 days"
          icon={CalendarRange}
        />
      </div>
    </div>
  );
}
