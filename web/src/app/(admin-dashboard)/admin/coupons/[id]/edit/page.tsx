"use client";

import { use } from "react";
import { Loader2 } from "lucide-react";
import { useAdminCoupon } from "@/hooks/use-admin-coupons";
import { ErrorState } from "@/components/shared/error-state";
import { CouponWizardForm } from "@/components/admin/coupon-wizard-form";

interface EditCouponPageProps {
  params: Promise<{ id: string }>;
}

export default function EditCouponPage({ params }: EditCouponPageProps) {
  const { id } = use(params);
  const couponId = parseInt(id, 10);
  const coupon = useAdminCoupon(couponId);

  if (coupon.isLoading) {
    return (
      <div className="flex items-center justify-center py-20" role="status">
        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" aria-hidden="true" />
        <span className="sr-only">Loading coupon...</span>
      </div>
    );
  }

  if (coupon.isError || !coupon.data) {
    return (
      <ErrorState
        message="Failed to load coupon"
        onRetry={() => coupon.refetch()}
      />
    );
  }

  return (
    <div className="py-6">
      <CouponWizardForm coupon={coupon.data} />
    </div>
  );
}
