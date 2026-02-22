"use client";

import { Dumbbell } from "lucide-react";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { ProgramViewer } from "@/components/trainee-dashboard/program-viewer";
import { useTraineeDashboardPrograms } from "@/hooks/use-trainee-dashboard";

export default function ProgramPage() {
  const { data: programs, isLoading, isError, refetch } =
    useTraineeDashboardPrograms();

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="My Program"
          description="Your assigned workout program"
        />
        <LoadingSpinner label="Loading program..." />
      </div>
    );
  }

  if (isError) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader
            title="My Program"
            description="Your assigned workout program"
          />
          <ErrorState
            message="Failed to load your program. Please try again."
            onRetry={() => refetch()}
          />
        </div>
      </PageTransition>
    );
  }

  if (!programs?.length) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader
            title="My Program"
            description="Your assigned workout program"
          />
          <EmptyState
            icon={Dumbbell}
            title="No program assigned"
            description="Your trainer hasn't assigned a workout program yet. Check back soon!"
          />
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="My Program"
          description="Your assigned workout program"
        />
        <ProgramViewer programs={programs} />
      </div>
    </PageTransition>
  );
}
