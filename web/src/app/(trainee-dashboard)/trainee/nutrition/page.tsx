"use client";

import { PageTransition } from "@/components/shared/page-transition";
import { PageHeader } from "@/components/shared/page-header";
import { NutritionPage } from "@/components/trainee-dashboard/nutrition-page";

export default function TraineeNutritionPage() {
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Nutrition"
          description="Track your daily meals and macro goals."
        />
        <NutritionPage />
      </div>
    </PageTransition>
  );
}
