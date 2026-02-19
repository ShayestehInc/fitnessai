"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { StripeConnectSetup } from "@/components/ambassador/stripe-connect-setup";
import { PayoutHistory } from "@/components/ambassador/payout-history";

export default function AmbassadorPayoutsPage() {
  return (
    <PageTransition>
      <div className="max-w-2xl space-y-6">
        <PageHeader
          title="Payouts"
          description="Manage your payout account and view history"
        />
        <StripeConnectSetup />
        <PayoutHistory />
      </div>
    </PageTransition>
  );
}
