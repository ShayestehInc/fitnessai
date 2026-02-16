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

export default function AdminDashboardPage() {
  const dashboard = useAdminDashboard();

  if (dashboard.isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Admin Dashboard"
          description="Platform overview and management"
        />
        <AdminDashboardSkeleton />
      </div>
    );
  }

  if (dashboard.isError) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Admin Dashboard"
          description="Platform overview and management"
        />
        <ErrorState
          message="Failed to load dashboard data"
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
        title="Admin Dashboard"
        description="Platform overview and management"
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
