"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { StripeConnectSetup } from "@/components/ambassador/stripe-connect-setup";
import { PayoutHistory } from "@/components/ambassador/payout-history";
import { useLocale } from "@/providers/locale-provider";

export default function AmbassadorPayoutsPage() {
  const { t } = useLocale();
  return (
    <PageTransition>
      <div className="max-w-2xl space-y-6">
        <PageHeader
          title={t("ambassador.payouts")}
          description={t("ambassador.payoutsDesc")}
        />
        <StripeConnectSetup />
        <PayoutHistory />
      </div>
    </PageTransition>
  );
}
