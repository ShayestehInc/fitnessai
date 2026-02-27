"use client";

import { PageHeader } from "@/components/shared/page-header";
import { AdherenceSection } from "@/components/analytics/adherence-section";
import { ProgressSection } from "@/components/analytics/progress-section";
import { RevenueSection } from "@/components/analytics/revenue-section";
import { RetentionSection } from "@/components/analytics/retention/retention-section";

export default function AnalyticsPage() {
  return (
    <div className="space-y-8">
      <PageHeader
        title="Analytics"
        description="Track trainee performance, adherence, retention, and revenue"
      />
      <RetentionSection />
      <AdherenceSection />
      <ProgressSection />
      <RevenueSection />
    </div>
  );
}
