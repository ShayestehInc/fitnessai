"use client";

import { useMemo } from "react";
import { Trophy } from "lucide-react";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { AchievementsGrid } from "@/components/trainee-dashboard/achievements-grid";
import { useAchievements } from "@/hooks/use-trainee-achievements";

export default function AchievementsPage() {
  const { data: achievements, isLoading, isError, refetch } = useAchievements();

  const stats = useMemo(() => {
    if (!achievements?.length) return { earned: 0, total: 0 };
    const earned = achievements.filter((a) => a.earned).length;
    return { earned, total: achievements.length };
  }, [achievements]);

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Achievements"
          description="Your fitness milestones"
        />
        <LoadingSpinner label="Loading achievements..." />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Achievements"
          description="Your fitness milestones"
        />
        <ErrorState
          message="Failed to load achievements. Please try again."
          onRetry={() => refetch()}
        />
      </div>
    );
  }

  if (!achievements?.length) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader
            title="Achievements"
            description="Your fitness milestones"
          />
          <EmptyState
            icon={Trophy}
            title="No achievements available"
            description="Achievements will appear here as you progress through your fitness journey."
          />
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Achievements"
          description={`${stats.earned} of ${stats.total} achievements earned`}
        />
        <AchievementsGrid achievements={achievements} />
      </div>
    </PageTransition>
  );
}
