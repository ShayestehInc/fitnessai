"use client";

import { useState } from "react";
import { PageTransition } from "@/components/shared/page-transition";
import { PageHeader } from "@/components/shared/page-header";
import {
  WeightTrendChart,
  WorkoutVolumeChart,
  WeeklyAdherenceCard,
} from "@/components/trainee-dashboard/trainee-progress-charts";
import { WeightCheckInPanel } from "@/components/trainee-dashboard/weight-checkin-panel";
import { useLocale } from "@/providers/locale-provider";

export default function TraineeProgressPage() {
  const { t } = useLocale();
  const [weightDialogOpen, setWeightDialogOpen] = useState(false);

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={t("nav.progress")}
          description={t("progress.description")}
        />

        <div className="grid gap-4 sm:gap-6 lg:grid-cols-2">
          <WeightTrendChart
            onOpenLogWeight={() => setWeightDialogOpen(true)}
          />
          <WorkoutVolumeChart />
        </div>

        <WeeklyAdherenceCard />
      </div>

      <WeightCheckInPanel
        open={weightDialogOpen}
        onOpenChange={setWeightDialogOpen}
      />
    </PageTransition>
  );
}
