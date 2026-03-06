"use client";

import { PageTransition } from "@/components/shared/page-transition";
import { PageHeader } from "@/components/shared/page-header";
import { WorkoutHistoryList } from "@/components/trainee-dashboard/workout-history-list";
import { useLocale } from "@/providers/locale-provider";

export default function TraineeHistoryPage() {
  const { t } = useLocale();
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={t("workout.history")}
          description={t("workout.viewHistory")}
        />
        <WorkoutHistoryList />
      </div>
    </PageTransition>
  );
}
