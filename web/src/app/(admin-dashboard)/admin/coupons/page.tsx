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

export default function AdminCouponsPage() {
  const [searchInput, setSearchInput] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [formOpen, setFormOpen] = useState(false);
  const [editingCoupon, setEditingCoupon] = useState<AdminCoupon | null>(null);
  const [detailCouponId, setDetailCouponId] = useState<number | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);

  const debouncedSearch = useDebounce(searchInput, 300);

  const filters = useMemo(
    () => ({
      search: debouncedSearch || undefined,
      status: statusFilter || undefined,
      type: typeFilter || undefined,
    }),
    [debouncedSearch, statusFilter, typeFilter],
  );

  const coupons = useAdminCoupons(filters);

  function handleCreate() {
    setEditingCoupon(null);
    setFormOpen(true);
  }

  function handleRowClick(coupon: AdminCouponListItem) {
    setDetailCouponId(coupon.id);
    setDetailOpen(true);
  }

  function handleEditFromDetail() {
    setDetailOpen(false);
    // We don't have the full coupon data from the list item, so we open the form
    // with null to trigger a create-style edit. The detail dialog fetches full data.
    setEditingCoupon(null);
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
          className="max-w-sm"
          aria-label="Search coupons"
        />
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="flex h-9 rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
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
          className="flex h-9 rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          aria-label="Filter by type"
        >
          {TYPE_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      </div>

      {coupons.isLoading && (
        <div className="space-y-2">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
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
            debouncedSearch || statusFilter || typeFilter
              ? "No coupons match your filters."
              : "Create your first coupon to offer discounts."
          }
          action={
            !debouncedSearch && !statusFilter && !typeFilter ? (
              <Button onClick={handleCreate}>Create Coupon</Button>
            ) : undefined
          }
        />
      )}

      {coupons.data && coupons.data.length > 0 && (
        <CouponList coupons={coupons.data} onRowClick={handleRowClick} />
      )}

      <CouponFormDialog
        key={editingCoupon?.id ?? "new"}
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
