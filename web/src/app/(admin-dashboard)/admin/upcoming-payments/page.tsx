"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { UpcomingPaymentsList } from "@/components/admin/upcoming-payments-list";

export default function UpcomingPaymentsPage() {
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Upcoming Payments"
          description="Subscription payments due soon"
        />
        <UpcomingPaymentsList />
      </div>
    </PageTransition>
  );
}
