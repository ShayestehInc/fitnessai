"use client";

import { useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import { Ticket, Plus } from "lucide-react";
import { useAdminCoupons } from "@/hooks/use-admin-coupons";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { CouponList } from "@/components/admin/coupon-list";
import { CouponDetailPanel } from "@/components/admin/coupon-detail-panel";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { SELECT_CLASSES } from "@/lib/admin-constants";
import type { AdminCoupon, AdminCouponListItem } from "@/types/admin";
import { useLocale } from "@/providers/locale-provider";

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
  const { t } = useLocale();
  const router = useRouter();
  const [searchInput, setSearchInput] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [appliesToFilter, setAppliesToFilter] = useState("");
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
    router.push("/admin/coupons/new");
  }

  function handleRowClick(coupon: AdminCouponListItem) {
    setDetailCouponId(coupon.id);
    setDetailOpen(true);
  }

  function handleEditFromDetail(coupon: AdminCoupon) {
    setDetailOpen(false);
    router.push(`/admin/coupons/${coupon.id}/edit`);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={t("admin.coupons")}
        description={t("ambassador.couponsDesc")}
        actions={
          <Button onClick={handleCreate}>
            <Plus className="mr-2 h-4 w-4" aria-hidden="true" />
            Create Coupon
          </Button>
        }
      />

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <Input
          placeholder={t("admin.searchByCode")}
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
          title={t("admin.noCoupons")}
          description={
            debouncedSearch || statusFilter || typeFilter || appliesToFilter
              ? "No coupons match your filters."
              : "Create your first coupon to offer discounts."
          }
          action={
            !debouncedSearch && !statusFilter && !typeFilter && !appliesToFilter ? (
              <Button onClick={handleCreate}>{t("admin.createCoupon")}</Button>
            ) : undefined
          }
        />
      )}

      {coupons.data && coupons.data.length > 0 && (
        <CouponList coupons={coupons.data} onRowClick={handleRowClick} />
      )}

      <CouponDetailPanel
        couponId={detailCouponId}
        open={detailOpen}
        onOpenChange={setDetailOpen}
        onEdit={handleEditFromDetail}
      />
    </div>
  );
}
