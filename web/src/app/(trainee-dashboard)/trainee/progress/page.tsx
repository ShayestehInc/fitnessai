"use client";

import { useState } from "react";
import { PageTransition } from "@/components/shared/page-transition";
import { PageHeader } from "@/components/shared/page-header";
import {
  WeightTrendChart,
  WorkoutVolumeChart,
  WeeklyAdherenceCard,
} from "@/components/trainee-dashboard/trainee-progress-charts";
import { WeightCheckInDialog } from "@/components/trainee-dashboard/weight-checkin-dialog";

export default function TraineeProgressPage() {
  const [weightDialogOpen, setWeightDialogOpen] = useState(false);

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Progress"
          description="Track your training progress and body weight trends."
        />

        <div className="grid gap-6 lg:grid-cols-2">
          <WeightTrendChart
            onOpenLogWeight={() => setWeightDialogOpen(true)}
          />
          <WorkoutVolumeChart />
        </div>

        <WeeklyAdherenceCard />
      </div>

      <WeightCheckInDialog
        open={weightDialogOpen}
        onOpenChange={setWeightDialogOpen}
      />
    </PageTransition>
  );
}
