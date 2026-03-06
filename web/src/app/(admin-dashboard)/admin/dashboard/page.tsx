"use client";

import { AlertTriangle } from "lucide-react";
import { useAdminDashboard } from "@/hooks/use-admin-dashboard";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { DashboardStats } from "@/components/admin/dashboard-stats";
import { RevenueCards } from "@/components/admin/revenue-cards";
import { TierBreakdown } from "@/components/admin/tier-breakdown";
import { PastDueAlerts } from "@/components/admin/past-due-alerts";
import { AdminDashboardSkeleton } from "@/components/admin/admin-dashboard-skeleton";
import { Badge } from "@/components/ui/badge";
import { useLocale } from "@/providers/locale-provider";

export default function AdminDashboardPage() {
  const { t } = useLocale();
  const dashboard = useAdminDashboard();

  if (dashboard.isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title={t("admin.dashboard")}
          description={t("admin.dashboardDesc")}
        />
        <AdminDashboardSkeleton />
      </div>
    );
  }

  if (dashboard.isError) {
    return (
      <div className="space-y-6">
        <PageHeader
          title={t("admin.dashboard")}
          description={t("admin.dashboardDesc")}
        />
        <ErrorState
          message={t("dashboard.failedToLoad")}
          onRetry={() => dashboard.refetch()}
        />
      </div>
    );
  }

  const stats = dashboard.data;
  if (!stats) return null;

  return (
    <div className="space-y-6">
      <PageHeader
        title={t("admin.dashboard")}
        description={t("admin.dashboardDesc")}
        actions={
          stats.past_due_count > 0 ? (
            <Badge
              variant="destructive"
              className="flex items-center gap-1"
            >
              <AlertTriangle className="h-3 w-3" aria-hidden="true" />
              {stats.past_due_count} past due
              <span className="sr-only"> subscriptions</span>
            </Badge>
          ) : undefined
        }
      />
      <DashboardStats stats={stats} />
      <RevenueCards stats={stats} />
      <div className="grid gap-6 lg:grid-cols-2">
        <TierBreakdown tierBreakdown={stats.tier_breakdown} />
        <PastDueAlerts />
      </div>
    </div>
  );
}
