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
import { useLocale } from "@/providers/locale-provider";

export default function AchievementsPage() {
  const { t } = useLocale();
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
          title={t("nav.achievements")}
          description={t("achievements.description")}
        />
        <LoadingSpinner label="Loading achievements..." />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader
          title={t("nav.achievements")}
          description={t("achievements.description")}
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
            title={t("nav.achievements")}
            description={t("achievements.description")}
          />
          <EmptyState
            icon={Trophy}
            title={t("achievements.noAchievements")}
            description={t("achievements.noAchievementsDesc")}
          />
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={t("nav.achievements")}
          description={`${stats.earned} of ${stats.total} achievements earned`}
        />
        <AchievementsGrid achievements={achievements} />
      </div>
    </PageTransition>
  );
}
