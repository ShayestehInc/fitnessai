"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { AmbassadorDashboardSkeleton } from "@/components/ambassador/ambassador-dashboard-skeleton";
import { DashboardEarningsCard } from "@/components/ambassador/dashboard-earnings-card";
import { EarningsChart } from "@/components/ambassador/earnings-chart";
import { ReferralStatusBreakdown } from "@/components/ambassador/referral-status-breakdown";
import { ReferralCodeCard } from "@/components/ambassador/referral-code-card";
import { RecentReferralsList } from "@/components/ambassador/recent-referrals-list";
import { useAmbassadorDashboard } from "@/hooks/use-ambassador";
import type { AmbassadorDashboardData } from "@/types/ambassador";

export default function AmbassadorDashboardPage() {
  const { data, isLoading, isError, refetch } = useAmbassadorDashboard();

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Ambassador Dashboard"
          description="Track your referrals and earnings"
        />
        <AmbassadorDashboardSkeleton />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Ambassador Dashboard"
          description="Track your referrals and earnings"
        />
        <ErrorState
          message="Failed to load dashboard"
          onRetry={() => refetch()}
        />
      </div>
    );
  }

  const dashboardData = data as AmbassadorDashboardData;

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Ambassador Dashboard"
          description="Track your referrals and earnings"
        />
        <DashboardEarningsCard data={dashboardData} />
        <EarningsChart data={dashboardData.monthly_earnings ?? []} />
        <div className="grid gap-6 md:grid-cols-2">
          <ReferralStatusBreakdown
            active={dashboardData.active_referrals}
            pending={dashboardData.pending_referrals}
            churned={dashboardData.churned_referrals}
          />
          <ReferralCodeCard />
        </div>
        <RecentReferralsList referrals={dashboardData.recent_referrals ?? []} />
      </div>
    </PageTransition>
  );
}
