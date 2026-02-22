"use client";

import { PageTransition } from "@/components/shared/page-transition";
import { ActiveWorkout } from "@/components/trainee-dashboard/active-workout";

export default function TraineeWorkoutPage() {
  return (
    <PageTransition>
      <ActiveWorkout />
    </PageTransition>
  );
}
