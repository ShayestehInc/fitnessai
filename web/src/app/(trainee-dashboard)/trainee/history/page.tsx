"use client";

import { PageTransition } from "@/components/shared/page-transition";
import { PageHeader } from "@/components/shared/page-header";
import { WorkoutHistoryList } from "@/components/trainee-dashboard/workout-history-list";

export default function TraineeHistoryPage() {
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Workout History"
          description="View your past workouts and track your progress over time."
        />
        <WorkoutHistoryList />
      </div>
    </PageTransition>
  );
}
