"use client";

import { format } from "date-fns";
import { Loader2 } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import {
  useAdminCoupon,
  useCouponUsages,
  useRevokeCoupon,
  useReactivateCoupon,
} from "@/hooks/use-admin-coupons";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";
import { COUPON_STATUS_VARIANT } from "@/lib/admin-constants";
import { formatCurrency, formatDiscount } from "@/lib/format-utils";
import type { AdminCoupon, AdminCouponUsage } from "@/types/admin";

interface CouponDetailDialogProps {
  couponId: number | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onEdit: (coupon: AdminCoupon) => void;
}

const usageColumns: Column<AdminCouponUsage>[] = [
  {
    key: "user",
    header: "User",
    cell: (row) => (
      <div className="min-w-0">
        <p className="truncate text-sm font-medium">{row.user_name || "N/A"}</p>
        <p className="truncate text-xs text-muted-foreground">
          {row.user_email}
        </p>
      </div>
    ),
  },
  {
    key: "discount",
    header: "Discount",
    cell: (row) => formatCurrency(row.discount_amount),
  },
  {
    key: "used_at",
    header: "Used At",
    className: "hidden md:table-cell",
    cell: (row) => format(new Date(row.used_at), "MMM d, yyyy HH:mm"),
  },
];

export function CouponDetailDialog({
  couponId,
  open,
  onOpenChange,
  onEdit,
}: CouponDetailDialogProps) {
  const coupon = useAdminCoupon(couponId ?? 0);
  const usages = useCouponUsages(couponId ?? 0);
  const revoke = useRevokeCoupon();
  const reactivate = useReactivateCoupon();

  const data = coupon.data;

  async function handleRevoke() {
    if (!data) return;
    try {
      await revoke.mutateAsync(data.id);
      toast.success(`Coupon "${data.code}" revoked`);
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  async function handleReactivate() {
    if (!data) return;
    try {
      await reactivate.mutateAsync(data.id);
      toast.success(`Coupon "${data.code}" reactivated`);
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  if (!couponId) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] max-w-2xl overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {data ? (
              <span className="inline-block max-w-[200px] truncate font-mono sm:max-w-[400px]" title={data.code}>{data.code}</span>
            ) : (
              "Coupon Details"
            )}
          </DialogTitle>
          <DialogDescription>
            {data?.description || "Coupon details"}
          </DialogDescription>
        </DialogHeader>

        {coupon.isLoading && (
          <div className="flex items-center justify-center py-8" role="status" aria-label="Loading coupon details">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" aria-hidden="true" />
            <span className="sr-only">Loading coupon details...</span>
          </div>
        )}

        {coupon.isError && (
          <div className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive" role="alert">
            Failed to load coupon details.{" "}
            <button
              onClick={() => coupon.refetch()}
              className="underline hover:no-underline"
            >
              Retry
            </button>
          </div>
        )}

        {data && (
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <Badge variant={COUPON_STATUS_VARIANT[data.status] ?? "secondary"}>
                {data.status.charAt(0).toUpperCase() + data.status.slice(1)}
              </Badge>
              <Badge variant="outline">
                {data.coupon_type === "free_trial"
                  ? "Free Trial"
                  : data.coupon_type.charAt(0).toUpperCase() +
                    data.coupon_type.slice(1)}
              </Badge>
            </div>

            <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-3">
              <div>
                <p className="text-muted-foreground">Discount</p>
                <p className="font-medium">
                  {formatDiscount(data.coupon_type, data.discount_value)}
                </p>
              </div>
              <div>
                <p className="text-muted-foreground">Applies To</p>
                <p className="font-medium capitalize">{data.applies_to}</p>
              </div>
              <div>
                <p className="text-muted-foreground">Usage</p>
                <p className="font-medium">
                  {data.current_uses}
                  {data.max_uses > 0 ? ` / ${data.max_uses}` : " / Unlimited"}
                </p>
              </div>
              <div>
                <p className="text-muted-foreground">Max Per User</p>
                <p className="font-medium">{data.max_uses_per_user}</p>
              </div>
              <div>
                <p className="text-muted-foreground">Valid From</p>
                <p className="font-medium">
                  {format(new Date(data.valid_from), "MMM d, yyyy")}
                </p>
              </div>
              <div>
                <p className="text-muted-foreground">Valid Until</p>
                <p className="font-medium">
                  {data.valid_until
                    ? format(new Date(data.valid_until), "MMM d, yyyy")
                    : "No expiry"}
                </p>
              </div>
            </div>

            <div className="flex gap-2">
              <Button variant="outline" size="sm" onClick={() => onEdit(data)}>
                Edit
              </Button>
              {data.status === "active" && (
                <Button
                  variant="destructive"
                  size="sm"
                  onClick={handleRevoke}
                  disabled={revoke.isPending}
                >
                  {revoke.isPending && (
                    <Loader2
                      className="mr-1 h-3 w-3 animate-spin"
                      aria-hidden="true"
                    />
                  )}
                  Revoke
                </Button>
              )}
              {(data.status === "revoked" || data.status === "exhausted") && (
                <Tooltip>
                  <TooltipTrigger asChild>
                    <span>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={handleReactivate}
                        disabled={
                          reactivate.isPending || data.status === "exhausted"
                        }
                      >
                        {reactivate.isPending && (
                          <Loader2
                            className="mr-1 h-3 w-3 animate-spin"
                            aria-hidden="true"
                          />
                        )}
                        Reactivate
                      </Button>
                    </span>
                  </TooltipTrigger>
                  {data.status === "exhausted" && (
                    <TooltipContent>
                      Cannot reactivate exhausted coupon
                    </TooltipContent>
                  )}
                </Tooltip>
              )}
            </div>

            <Separator />

            <div>
              <h4 className="mb-2 text-sm font-semibold">Usages</h4>
              {usages.isLoading && (
                <div className="flex items-center justify-center py-4" role="status" aria-label="Loading usages">
                  <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" aria-hidden="true" />
                  <span className="sr-only">Loading usages...</span>
                </div>
              )}
              {usages.isError && (
                <div className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive" role="alert">
                  Failed to load coupon usages.{" "}
                  <button
                    onClick={() => usages.refetch()}
                    className="underline hover:no-underline"
                  >
                    Retry
                  </button>
                </div>
              )}
              {usages.data && usages.data.length === 0 && (
                <p className="text-sm text-muted-foreground">
                  No usages recorded yet
                </p>
              )}
              {usages.data && usages.data.length > 0 && (
                <DataTable
                  columns={usageColumns}
                  data={usages.data}
                  keyExtractor={(row) => row.id}
                />
              )}
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
