"use client";

import { useState } from "react";
import { useFeatureRequests } from "@/hooks/use-feature-requests";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { FeatureRequestList } from "@/components/feature-requests/feature-request-list";
import { FeatureListSkeleton } from "@/components/feature-requests/feature-list-skeleton";
import type { FeatureRequestStatus } from "@/types/feature-request";

export default function FeatureRequestsPage() {
  const [statusFilter, setStatusFilter] = useState<FeatureRequestStatus | "">("");
  const [page] = useState(1);
  const { data, isLoading, isError, refetch } = useFeatureRequests(
    "votes",
    statusFilter,
    page,
  );

  if (isLoading) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title="Feature Requests" description="Suggest and vote on features" />
          <FeatureListSkeleton />
        </div>
      </PageTransition>
    );
  }

  if (isError) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title="Feature Requests" description="Suggest and vote on features" />
          <ErrorState message="Failed to load feature requests" onRetry={() => refetch()} />
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader title="Feature Requests" description="Suggest and vote on features" />
        <FeatureRequestList
          requests={data?.results ?? []}
          statusFilter={statusFilter}
          onStatusFilterChange={setStatusFilter}
        />
      </div>
    </PageTransition>
  );
}
