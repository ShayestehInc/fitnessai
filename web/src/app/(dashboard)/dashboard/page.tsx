"use client";

import Link from "next/link";
import { Users } from "lucide-react";
import { useDashboardStats, useDashboardOverview } from "@/hooks/use-dashboard";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import { StatsCards } from "@/components/dashboard/stats-cards";
import { RecentTrainees } from "@/components/dashboard/recent-trainees";
import { InactiveTrainees } from "@/components/dashboard/inactive-trainees";
import { DashboardSkeleton } from "@/components/dashboard/dashboard-skeleton";
import { useLocale } from "@/providers/locale-provider";

export default function DashboardPage() {
  const { t } = useLocale();
  const stats = useDashboardStats();
  const overview = useDashboardOverview();

  const isLoading = stats.isLoading || overview.isLoading;
  const isError = stats.isError || overview.isError;

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader title={t("nav.dashboard")} description={t("dashboard.description")} />
        <DashboardSkeleton />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title={t("nav.dashboard")} description={t("dashboard.description")} />
        <ErrorState
          message={t("dashboard.failedToLoad")}
          onRetry={() => {
            stats.refetch();
            overview.refetch();
          }}
        />
      </div>
    );
  }

  if (stats.data && stats.data.total_trainees === 0) {
    return (
      <div className="space-y-6">
        <PageHeader title={t("nav.dashboard")} description={t("dashboard.description")} />
        <EmptyState
          icon={Users}
          title={t("trainees.noTraineesYet")}
          description={t("trainees.noTraineesDesc")}
          action={
            <Button asChild>
              <Link href="/invitations">{t("invitations.createInvitation")}</Link>
            </Button>
          }
        />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader title={t("nav.dashboard")} description={t("dashboard.description")} />
      {stats.data && <StatsCards stats={stats.data} />}
      <div className="grid gap-6 lg:grid-cols-2">
        {overview.data && (
          <>
            <RecentTrainees trainees={overview.data.recent_trainees} />
            <InactiveTrainees trainees={overview.data.inactive_trainees} />
          </>
        )}
      </div>
    </div>
  );
}
