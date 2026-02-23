"use client";

import { useState, useMemo, useCallback } from "react";
import { Ticket, Plus, Loader2, Trash2 } from "lucide-react";
import {
  useAmbassadorAdminCoupons,
  useAmbassadorAdminCreateCoupon,
  useAmbassadorAdminDeleteCoupon,
} from "@/hooks/use-ambassador-admin-coupons";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";
import { SELECT_CLASSES, COUPON_STATUS_VARIANT } from "@/lib/admin-constants";

const STATUS_OPTIONS = [
  { value: "", label: "All Status" },
  { value: "active", label: "Active" },
  { value: "expired", label: "Expired" },
  { value: "revoked", label: "Revoked" },
  { value: "exhausted", label: "Exhausted" },
];

export default function AmbassadorCouponsPage() {
  const [searchInput, setSearchInput] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [createOpen, setCreateOpen] = useState(false);
  const [formData, setFormData] = useState({
    code: "",
    coupon_type: "percent",
    discount_value: "",
    applies_to: "both",
    max_uses: "0",
    description: "",
  });
  const [formError, setFormError] = useState<string | null>(null);

  const debouncedSearch = useDebounce(searchInput, 300);
  const filters = useMemo(
    () => ({
      search: debouncedSearch || undefined,
      status: statusFilter || undefined,
    }),
    [debouncedSearch, statusFilter],
  );

  const coupons = useAmbassadorAdminCoupons(filters);
  const createCoupon = useAmbassadorAdminCreateCoupon();
  const deleteCoupon = useAmbassadorAdminDeleteCoupon();

  const handleCreate = useCallback(async () => {
    setFormError(null);
    if (!formData.code || !formData.discount_value) {
      setFormError("Code and discount value are required.");
      return;
    }
    try {
      await createCoupon.mutateAsync({
        code: formData.code,
        coupon_type: formData.coupon_type,
        discount_value: formData.discount_value,
        applies_to: formData.applies_to,
        applicable_tiers: [],
        max_uses: parseInt(formData.max_uses, 10) || 0,
        max_uses_per_user: 1,
        valid_from: new Date().toISOString(),
        valid_until: null,
        description: formData.description,
      });
      toast.success("Coupon created successfully");
      setCreateOpen(false);
      setFormData({
        code: "",
        coupon_type: "percent",
        discount_value: "",
        applies_to: "both",
        max_uses: "0",
        description: "",
      });
    } catch (error) {
      setFormError(getErrorMessage(error));
    }
  }, [formData, createCoupon]);

  const handleDelete = useCallback(
    async (id: number) => {
      try {
        await deleteCoupon.mutateAsync(id);
        toast.success("Coupon deleted");
      } catch (error) {
        toast.error(getErrorMessage(error));
      }
    },
    [deleteCoupon],
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title="Coupons"
        description="Create and manage discount coupons"
        actions={
          <Button onClick={() => setCreateOpen(true)}>
            <Plus className="mr-2 h-4 w-4" aria-hidden="true" />
            Create Coupon
          </Button>
        }
      />

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <Input
          placeholder="Search by code..."
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          className="max-w-sm"
          aria-label="Search coupons"
        />
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className={SELECT_CLASSES}
          aria-label="Filter by status"
        >
          {STATUS_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      </div>

      {coupons.isLoading && (
        <div className="space-y-2" role="status" aria-label="Loading coupons">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
          <span className="sr-only">Loading coupons...</span>
        </div>
      )}

      {coupons.isError && (
        <ErrorState
          message="Failed to load coupons"
          onRetry={() => coupons.refetch()}
        />
      )}

      {coupons.data && coupons.data.length === 0 && (
        <EmptyState
          icon={Ticket}
          title="No coupons found"
          description={
            debouncedSearch || statusFilter
              ? "No coupons match your filters."
              : "Create your first coupon to offer discounts."
          }
          action={
            !debouncedSearch && !statusFilter ? (
              <Button onClick={() => setCreateOpen(true)}>
                Create Coupon
              </Button>
            ) : undefined
          }
        />
      )}

      {coupons.data && coupons.data.length > 0 && (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Code</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Value</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Uses</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {coupons.data.map((coupon) => (
                <TableRow key={coupon.id}>
                  <TableCell className="font-mono font-medium">
                    {coupon.code}
                  </TableCell>
                  <TableCell className="capitalize">
                    {coupon.coupon_type.replace("_", " ")}
                  </TableCell>
                  <TableCell>
                    {coupon.coupon_type === "percent"
                      ? `${coupon.discount_value}%`
                      : coupon.coupon_type === "fixed"
                        ? `$${coupon.discount_value}`
                        : `${coupon.discount_value} days`}
                  </TableCell>
                  <TableCell>
                    <Badge
                      variant={
                        (COUPON_STATUS_VARIANT[
                          coupon.status as keyof typeof COUPON_STATUS_VARIANT
                        ] ?? "secondary") as
                          | "default"
                          | "secondary"
                          | "destructive"
                          | "outline"
                      }
                    >
                      {coupon.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {coupon.current_uses}
                    {coupon.max_uses > 0 ? `/${coupon.max_uses}` : ""}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-destructive hover:text-destructive"
                      onClick={() => handleDelete(coupon.id)}
                      disabled={deleteCoupon.isPending}
                      aria-label={`Delete coupon ${coupon.code}`}
                    >
                      <Trash2 className="h-4 w-4" aria-hidden="true" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      {/* Create Coupon Dialog */}
      <Dialog
        open={createOpen}
        onOpenChange={(open) => {
          setCreateOpen(open);
          if (!open) {
            setFormError(null);
            setFormData({
              code: "",
              coupon_type: "percent",
              discount_value: "",
              applies_to: "both",
              max_uses: "0",
              description: "",
            });
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Coupon</DialogTitle>
            <DialogDescription>
              Create a new discount coupon for trainers or trainees.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="coupon-code">Code</Label>
              <Input
                id="coupon-code"
                value={formData.code}
                onChange={(e) =>
                  setFormData((d) => ({
                    ...d,
                    code: e.target.value.toUpperCase(),
                  }))
                }
                placeholder="e.g., SUMMER20"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="coupon-type">Type</Label>
                <select
                  id="coupon-type"
                  value={formData.coupon_type}
                  onChange={(e) =>
                    setFormData((d) => ({ ...d, coupon_type: e.target.value }))
                  }
                  className={SELECT_CLASSES}
                >
                  <option value="percent">Percentage</option>
                  <option value="fixed">Fixed Amount</option>
                  <option value="free_trial">Free Trial</option>
                </select>
              </div>
              <div className="grid gap-2">
                <Label htmlFor="coupon-value">Value</Label>
                <Input
                  id="coupon-value"
                  type="number"
                  value={formData.discount_value}
                  onChange={(e) =>
                    setFormData((d) => ({
                      ...d,
                      discount_value: e.target.value,
                    }))
                  }
                  placeholder={
                    formData.coupon_type === "percent"
                      ? "e.g., 20"
                      : formData.coupon_type === "fixed"
                        ? "e.g., 10.00"
                        : "e.g., 14"
                  }
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="coupon-applies">Applies To</Label>
                <select
                  id="coupon-applies"
                  value={formData.applies_to}
                  onChange={(e) =>
                    setFormData((d) => ({ ...d, applies_to: e.target.value }))
                  }
                  className={SELECT_CLASSES}
                >
                  <option value="both">Both</option>
                  <option value="trainer">Trainer Subscription</option>
                  <option value="trainee">Trainee Coaching</option>
                </select>
              </div>
              <div className="grid gap-2">
                <Label htmlFor="coupon-max-uses">Max Uses (0 = unlimited)</Label>
                <Input
                  id="coupon-max-uses"
                  type="number"
                  value={formData.max_uses}
                  onChange={(e) =>
                    setFormData((d) => ({ ...d, max_uses: e.target.value }))
                  }
                />
              </div>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="coupon-desc">Description (optional)</Label>
              <Input
                id="coupon-desc"
                value={formData.description}
                onChange={(e) =>
                  setFormData((d) => ({ ...d, description: e.target.value }))
                }
                placeholder="Internal description"
              />
            </div>
            {formError && (
              <div
                className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive"
                role="alert"
              >
                {formError}
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setCreateOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleCreate}
              disabled={createCoupon.isPending}
            >
              {createCoupon.isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              Create
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
