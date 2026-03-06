"use client";

import {
  AlertTriangle,
  CalendarClock,
  CalendarDays,
  CalendarRange,
} from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import { formatCurrency } from "@/lib/format-utils";
import type { AdminDashboardStats } from "@/types/admin";
import { useLocale } from "@/providers/locale-provider";

interface RevenueCardsProps {
  stats: AdminDashboardStats;
}

export function RevenueCards({ stats }: RevenueCardsProps) {
  const { t } = useLocale();
  return (
    <div className="space-y-3">
      <h2 className="text-lg font-semibold">Revenue & Payments</h2>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title={t("admin.totalPastDue")}
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
          title={t("admin.paymentsDueToday")}
          value={stats.payments_due_today}
          description="Active subscriptions"
          icon={CalendarClock}
        />
        <StatCard
          title={t("admin.dueThisWeek")}
          value={stats.payments_due_this_week}
          description={t("admin.next7Days")}
          icon={CalendarDays}
        />
        <StatCard
          title={t("admin.dueThisMonth")}
          value={stats.payments_due_this_month}
          description={t("admin.next30Days")}
          icon={CalendarRange}
        />
      </div>
    </div>
  );
}
