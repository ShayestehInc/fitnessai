"use client";

import { format } from "date-fns";
import { Loader2, Check, DollarSign } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { SlideOverPanel } from "@/components/ui/slide-over-panel";
import {
  useAdminAmbassadorDetail,
  useBulkApproveCommissions,
  useBulkPayCommissions,
  useTriggerPayout,
} from "@/hooks/use-admin-ambassadors";
import { formatCurrency } from "@/lib/format-utils";
import { getErrorMessage } from "@/lib/error-utils";
import { Skeleton } from "@/components/ui/skeleton";
import type { Ambassador } from "@/types/ambassador";

interface AmbassadorDetailPanelProps {
  ambassador: Ambassador | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function AmbassadorDetailPanel({
  ambassador,
  open,
  onOpenChange,
}: AmbassadorDetailPanelProps) {
  if (!ambassador) return null;

  return (
    <SlideOverPanel
      open={open}
      onOpenChange={onOpenChange}
      title={ambassador.user.email}
      description="Ambassador details and commission management"
      width="lg"
    >
      <AmbassadorDetailContent ambassador={ambassador} />
    </SlideOverPanel>
  );
}

function AmbassadorDetailContent({ ambassador }: { ambassador: Ambassador }) {
  const { data: detail, isLoading } = useAdminAmbassadorDetail(ambassador.id);
  const bulkApproveMutation = useBulkApproveCommissions(ambassador.id);
  const bulkPayMutation = useBulkPayCommissions(ambassador.id);
  const payoutMutation = useTriggerPayout(ambassador.id);

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-20 w-full" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  const ambassadorData = detail ?? ambassador;

  return (
    <div className="space-y-4">
      {/* Summary Stats */}
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-md border p-3 text-center">
          <p className="text-xs text-muted-foreground">Referrals</p>
          <p className="text-lg font-bold">{ambassadorData.total_referrals ?? 0}</p>
        </div>
        <div className="rounded-md border p-3 text-center">
          <p className="text-xs text-muted-foreground">Earnings</p>
          <p className="text-lg font-bold text-green-600">
            {formatCurrency(ambassadorData.total_earnings ?? 0)}
          </p>
        </div>
        <div className="rounded-md border p-3 text-center">
          <p className="text-xs text-muted-foreground">Commission</p>
          <p className="text-lg font-bold">{ambassadorData.commission_rate ?? 10}%</p>
        </div>
      </div>

      <Separator />

      {/* Actions */}
      <div className="flex flex-wrap gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={() =>
            bulkApproveMutation.mutate(undefined, {
              onSuccess: () => toast.success("All commissions approved"),
              onError: (err) => toast.error(getErrorMessage(err)),
            })
          }
          disabled={bulkApproveMutation.isPending}
        >
          {bulkApproveMutation.isPending ? (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
          ) : (
            <Check className="mr-2 h-4 w-4" aria-hidden="true" />
          )}
          Approve All
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() =>
            bulkPayMutation.mutate(undefined, {
              onSuccess: () => toast.success("All commissions marked as paid"),
              onError: (err) => toast.error(getErrorMessage(err)),
            })
          }
          disabled={bulkPayMutation.isPending}
        >
          {bulkPayMutation.isPending ? (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
          ) : (
            <DollarSign className="mr-2 h-4 w-4" aria-hidden="true" />
          )}
          Pay All
        </Button>
        <Button
          size="sm"
          onClick={() =>
            payoutMutation.mutate(undefined, {
              onSuccess: () => toast.success("Payout triggered"),
              onError: (err) => toast.error(getErrorMessage(err)),
            })
          }
          disabled={payoutMutation.isPending}
        >
          {payoutMutation.isPending ? (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
          ) : (
            <DollarSign className="mr-2 h-4 w-4" aria-hidden="true" />
          )}
          Trigger Payout
        </Button>
      </div>

      {/* Info */}
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-muted-foreground">Status</span>
          <Badge variant={ambassadorData.is_active ? "default" : "secondary"}>
            {ambassadorData.is_active ? "Active" : "Inactive"}
          </Badge>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Referral Code</span>
          <span className="font-mono font-medium">
            {ambassadorData.referral_code ?? "N/A"}
          </span>
        </div>
        {ambassadorData.created_at && (
          <div className="flex justify-between">
            <span className="text-muted-foreground">Created</span>
            <span>
              {format(new Date(ambassadorData.created_at), "MMM d, yyyy")}
            </span>
          </div>
        )}
      </div>
    </div>
  );
}
