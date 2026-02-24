"use client";

import { useState, useMemo } from "react";
import { Ticket, Plus } from "lucide-react";
import { useAdminCoupons } from "@/hooks/use-admin-coupons";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { CouponList } from "@/components/admin/coupon-list";
import { CouponFormDialog } from "@/components/admin/coupon-form-dialog";
import { CouponDetailDialog } from "@/components/admin/coupon-detail-dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { SELECT_CLASSES } from "@/lib/admin-constants";
import type { AdminCoupon, AdminCouponListItem } from "@/types/admin";

const STATUS_OPTIONS = [
  { value: "", label: "All Status" },
  { value: "active", label: "Active" },
  { value: "expired", label: "Expired" },
  { value: "revoked", label: "Revoked" },
  { value: "exhausted", label: "Exhausted" },
];

const TYPE_OPTIONS = [
  { value: "", label: "All Types" },
  { value: "percent", label: "Percentage" },
  { value: "fixed", label: "Fixed Amount" },
  { value: "free_trial", label: "Free Trial" },
];

const APPLIES_TO_OPTIONS = [
  { value: "", label: "All Targets" },
  { value: "trainer", label: "Trainer" },
  { value: "trainee", label: "Trainee" },
  { value: "both", label: "Both" },
];

export default function AdminCouponsPage() {
  const [searchInput, setSearchInput] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [appliesToFilter, setAppliesToFilter] = useState("");
  const [formOpen, setFormOpen] = useState(false);
  const [formKey, setFormKey] = useState(0);
  const [editingCoupon, setEditingCoupon] = useState<AdminCoupon | null>(null);
  const [detailCouponId, setDetailCouponId] = useState<number | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);

  const debouncedSearch = useDebounce(searchInput, 300);

  const filters = useMemo(
    () => ({
      search: debouncedSearch || undefined,
      status: statusFilter || undefined,
      type: typeFilter || undefined,
      applies_to: appliesToFilter || undefined,
    }),
    [debouncedSearch, statusFilter, typeFilter, appliesToFilter],
  );

  const coupons = useAdminCoupons(filters);

  function handleCreate() {
    setEditingCoupon(null);
    setFormKey((k) => k + 1);
    setFormOpen(true);
  }

  function handleRowClick(coupon: AdminCouponListItem) {
    setDetailCouponId(coupon.id);
    setDetailOpen(true);
  }

  function handleEditFromDetail(coupon: AdminCoupon) {
    setDetailOpen(false);
    setEditingCoupon(coupon);
    setFormOpen(true);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Coupons"
        description="Manage discount coupons"
        actions={
          <Button onClick={handleCreate}>
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
          className="w-full sm:max-w-sm"
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
        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className={SELECT_CLASSES}
          aria-label="Filter by type"
        >
          {TYPE_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
        <select
          value={appliesToFilter}
          onChange={(e) => setAppliesToFilter(e.target.value)}
          className={SELECT_CLASSES}
          aria-label="Filter by target"
        >
          {APPLIES_TO_OPTIONS.map((o) => (
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
            debouncedSearch || statusFilter || typeFilter || appliesToFilter
              ? "No coupons match your filters."
              : "Create your first coupon to offer discounts."
          }
          action={
            !debouncedSearch && !statusFilter && !typeFilter && !appliesToFilter ? (
              <Button onClick={handleCreate}>Create Coupon</Button>
            ) : undefined
          }
        />
      )}

      {coupons.data && coupons.data.length > 0 && (
        <CouponList coupons={coupons.data} onRowClick={handleRowClick} />
      )}

      <CouponFormDialog
        key={editingCoupon?.id ?? `new-${formKey}`}
        coupon={editingCoupon}
        open={formOpen}
        onOpenChange={setFormOpen}
      />

      <CouponDetailDialog
        couponId={detailCouponId}
        open={detailOpen}
        onOpenChange={setDetailOpen}
        onEdit={handleEditFromDetail}
      />
    </div>
  );
}
