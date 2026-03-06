"use client";

import { PageHeader } from "@/components/shared/page-header";
import { AdherenceSection } from "@/components/analytics/adherence-section";
import { ProgressSection } from "@/components/analytics/progress-section";
import { RevenueSection } from "@/components/analytics/revenue-section";
import { RetentionSection } from "@/components/analytics/retention/retention-section";
import { useLocale } from "@/providers/locale-provider";

export default function AnalyticsPage() {
  const { t } = useLocale();
  return (
    <div className="space-y-8">
      <PageHeader
        title={t("nav.analytics")}
        description={t("analytics.description")}
      />
      <RetentionSection />
      <AdherenceSection />
      <ProgressSection />
      <RevenueSection />
    </div>
  );
}
