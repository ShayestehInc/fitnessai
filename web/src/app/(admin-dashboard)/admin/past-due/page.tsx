"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { PastDueFullList } from "@/components/admin/past-due-full-list";
import { useLocale } from "@/providers/locale-provider";

export default function PastDuePage() {
  const { t } = useLocale();
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={t("admin.pastDue")}
          description={t("admin.pastDueDesc")}
        />
        <PastDueFullList />
      </div>
    </PageTransition>
  );
}
