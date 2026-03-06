"use client";

import { PageTransition } from "@/components/shared/page-transition";
import { PageHeader } from "@/components/shared/page-header";
import { NutritionPage } from "@/components/trainee-dashboard/nutrition-page";
import { useLocale } from "@/providers/locale-provider";

export default function TraineeNutritionPage() {
  const { t } = useLocale();
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={t("nav.nutrition")}
          description={t("nutrition.description")}
        />
        <NutritionPage />
      </div>
    </PageTransition>
  );
}
