"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ReferralList } from "@/components/ambassador/referral-list";
import { useLocale } from "@/providers/locale-provider";

export default function AmbassadorReferralsPage() {
  const { t } = useLocale();
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={t("ambassador.referrals")}
          description="All trainers you have referred"
        />
        <ReferralList />
      </div>
    </PageTransition>
  );
}
