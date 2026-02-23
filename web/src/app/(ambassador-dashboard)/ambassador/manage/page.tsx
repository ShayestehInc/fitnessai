"use client";

import { Users, CreditCard, Layers } from "lucide-react";
import { useAmbassadorAdminDashboard } from "@/hooks/use-ambassador-admin-dashboard";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { TIER_COLORS } from "@/lib/admin-constants";
import { Badge } from "@/components/ui/badge";

export default function AmbassadorManagePage() {
  const dashboard = useAmbassadorAdminDashboard();

  if (dashboard.isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Manage"
          description="Overview of your trainers and platform"
        />
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-28 w-full" />
          ))}
        </div>
      </div>
    );
  }

  if (dashboard.isError) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Manage"
          description="Overview of your trainers and platform"
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

  const tierEntries = Object.entries(stats.tier_breakdown);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Manage"
        description="Overview of your trainers and platform"
      />

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Total Trainers
            </CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total_trainers}</div>
            <p className="text-xs text-muted-foreground">
              {stats.active_trainers} active
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Total Trainees
            </CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total_trainees}</div>
            <p className="text-xs text-muted-foreground">
              Across your trainers
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">MRR</CardTitle>
            <CreditCard className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${stats.monthly_recurring_revenue}
            </div>
            <p className="text-xs text-muted-foreground">
              Monthly recurring revenue
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Commission Rate
            </CardTitle>
            <Layers className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {(parseFloat(stats.commission_rate) * 100).toFixed(0)}%
            </div>
            <p className="text-xs text-muted-foreground">Your rate</p>
          </CardContent>
        </Card>
      </div>

      {tierEntries.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Tier Breakdown</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-3">
              {tierEntries.map(([tier, count]) => (
                <Badge
                  key={tier}
                  variant="secondary"
                  className={
                    TIER_COLORS[tier as keyof typeof TIER_COLORS] ?? ""
                  }
                >
                  {tier}: {count}
                </Badge>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
