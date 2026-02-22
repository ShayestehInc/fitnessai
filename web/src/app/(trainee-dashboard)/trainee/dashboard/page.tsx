"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { TodaysWorkoutCard } from "@/components/trainee-dashboard/todays-workout-card";
import { NutritionSummaryCard } from "@/components/trainee-dashboard/nutrition-summary-card";
import { WeightTrendCard } from "@/components/trainee-dashboard/weight-trend-card";
import { WeeklyProgressCard } from "@/components/trainee-dashboard/weekly-progress-card";
import { useAuth } from "@/hooks/use-auth";

export default function TraineeDashboardPage() {
  const { user } = useAuth();
  const firstName = user?.first_name || "there";

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={`Welcome back, ${firstName}`}
          description="Here's your fitness overview for today."
        />
        <div className="grid gap-4 md:grid-cols-2">
          <TodaysWorkoutCard />
          <NutritionSummaryCard />
          <WeightTrendCard />
          <WeeklyProgressCard />
        </div>
      </div>
    </PageTransition>
  );
}
