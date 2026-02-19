"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ReferralList } from "@/components/ambassador/referral-list";

export default function AmbassadorReferralsPage() {
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Referrals"
          description="All trainers you have referred"
        />
        <ReferralList />
      </div>
    </PageTransition>
  );
}
