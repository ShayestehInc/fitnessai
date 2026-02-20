"use client";

import { useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useFeatureRequests } from "@/hooks/use-feature-requests";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { FeatureRequestList } from "@/components/feature-requests/feature-request-list";
import { FeatureListSkeleton } from "@/components/feature-requests/feature-list-skeleton";
import type { FeatureRequestStatus } from "@/types/feature-request";

export default function FeatureRequestsPage() {
  const [statusFilter, setStatusFilter] = useState<FeatureRequestStatus | "">("");
  const [page, setPage] = useState(1);
  const { data, isLoading, isError, refetch } = useFeatureRequests(
    "votes",
    statusFilter,
    page,
  );

  const hasNextPage = Boolean(data?.next);
  const hasPrevPage = page > 1;

  function handleStatusFilterChange(status: FeatureRequestStatus | "") {
    setStatusFilter(status);
    setPage(1);
  }

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
          onStatusFilterChange={handleStatusFilterChange}
        />
        {(hasPrevPage || hasNextPage) && (
          <nav className="flex items-center justify-between" aria-label="Feature request pagination">
            <Button
              variant="outline"
              size="sm"
              disabled={!hasPrevPage}
              onClick={() => setPage((p) => p - 1)}
              aria-label="Go to previous page"
            >
              <ChevronLeft className="mr-1 h-4 w-4" aria-hidden="true" />
              Previous
            </Button>
            <span className="text-sm text-muted-foreground" aria-current="page">
              Page {page}
            </span>
            <Button
              variant="outline"
              size="sm"
              disabled={!hasNextPage}
              onClick={() => setPage((p) => p + 1)}
              aria-label="Go to next page"
            >
              Next
              <ChevronRight className="ml-1 h-4 w-4" aria-hidden="true" />
            </Button>
          </nav>
        )}
      </div>
    </PageTransition>
  );
}
