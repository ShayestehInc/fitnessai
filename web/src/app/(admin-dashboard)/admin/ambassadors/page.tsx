"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { AmbassadorList } from "@/components/admin/ambassador-list";
import { useLocale } from "@/providers/locale-provider";

export default function AdminAmbassadorsPage() {
  const { t } = useLocale();
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={t("admin.ambassadors")}
          description={t("admin.ambassadorsDesc")}
        />
        <AmbassadorList />
      </div>
    </PageTransition>
  );
}
