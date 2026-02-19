"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { AmbassadorList } from "@/components/admin/ambassador-list";

export default function AdminAmbassadorsPage() {
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Ambassadors"
          description="Manage ambassador accounts and commissions"
        />
        <AmbassadorList />
      </div>
    </PageTransition>
  );
}
