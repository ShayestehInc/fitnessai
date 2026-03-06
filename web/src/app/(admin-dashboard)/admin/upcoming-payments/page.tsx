"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { UpcomingPaymentsList } from "@/components/admin/upcoming-payments-list";
import { useLocale } from "@/providers/locale-provider";

export default function UpcomingPaymentsPage() {
  const { t } = useLocale();
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={t("admin.upcomingPayments")}
          description={t("admin.upcomingDesc")}
        />
        <UpcomingPaymentsList />
      </div>
    </PageTransition>
  );
}
