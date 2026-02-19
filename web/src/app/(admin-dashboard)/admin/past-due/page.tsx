"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { PastDueFullList } from "@/components/admin/past-due-full-list";

export default function PastDuePage() {
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Past Due"
          description="Trainers with overdue subscription payments"
        />
        <PastDueFullList />
      </div>
    </PageTransition>
  );
}
