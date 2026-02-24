"use client";

import { useState, useMemo } from "react";
import { useSearchParams } from "next/navigation";
import { CreditCard } from "lucide-react";
import { useAdminSubscriptions } from "@/hooks/use-admin-subscriptions";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { SubscriptionList } from "@/components/admin/subscription-list";
import { SubscriptionDetailDialog } from "@/components/admin/subscription-detail-dialog";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { SELECT_CLASSES } from "@/lib/admin-constants";
import type { AdminSubscriptionListItem } from "@/types/admin";

const STATUS_OPTIONS = [
  { value: "", label: "All Status" },
  { value: "active", label: "Active" },
  { value: "past_due", label: "Past Due" },
  { value: "canceled", label: "Canceled" },
  { value: "trialing", label: "Trialing" },
  { value: "suspended", label: "Suspended" },
];

const TIER_OPTIONS = [
  { value: "", label: "All Tiers" },
  { value: "FREE", label: "Free" },
  { value: "STARTER", label: "Starter" },
  { value: "PRO", label: "Pro" },
  { value: "ENTERPRISE", label: "Enterprise" },
];

const UPCOMING_OPTIONS = [
  { value: "", label: "All Payments" },
  { value: "7", label: "Due in 7 days" },
  { value: "14", label: "Due in 14 days" },
  { value: "30", label: "Due in 30 days" },
];

export default function AdminSubscriptionsPage() {
  const searchParams = useSearchParams();
  const initialPastDue = searchParams.get("past_due") === "true";

  const [searchInput, setSearchInput] = useState("");
  const [statusFilter, setStatusFilter] = useState(
    initialPastDue ? "past_due" : "",
  );
  const [tierFilter, setTierFilter] = useState("");
  const [upcomingFilter, setUpcomingFilter] = useState("");
  const [selectedSubId, setSelectedSubId] = useState<number | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);

  const debouncedSearch = useDebounce(searchInput, 300);

  const filters = useMemo(
    () => ({
      search: debouncedSearch || undefined,
      status: statusFilter || undefined,
      tier: tierFilter || undefined,
      upcoming_days: upcomingFilter ? parseInt(upcomingFilter, 10) : undefined,
    }),
    [debouncedSearch, statusFilter, tierFilter, upcomingFilter],
  );

  const subscriptions = useAdminSubscriptions(filters);

  function handleRowClick(sub: AdminSubscriptionListItem) {
    setSelectedSubId(sub.id);
    setDetailOpen(true);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Subscriptions"
        description="Manage trainer subscriptions"
      />

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <Input
          placeholder="Search by email..."
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          className="w-full sm:max-w-sm"
          aria-label="Search subscriptions"
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
          value={tierFilter}
          onChange={(e) => setTierFilter(e.target.value)}
          className={SELECT_CLASSES}
          aria-label="Filter by tier"
        >
          {TIER_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
        <select
          value={upcomingFilter}
          onChange={(e) => setUpcomingFilter(e.target.value)}
          className={SELECT_CLASSES}
          aria-label="Filter by upcoming payments"
        >
          {UPCOMING_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      </div>

      {subscriptions.isLoading && (
        <div className="space-y-2" role="status" aria-label="Loading subscriptions">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
          <span className="sr-only">Loading subscriptions...</span>
        </div>
      )}

      {subscriptions.isError && (
        <ErrorState
          message="Failed to load subscriptions"
          onRetry={() => subscriptions.refetch()}
        />
      )}

      {subscriptions.data && subscriptions.data.length === 0 && (
        <EmptyState
          icon={CreditCard}
          title="No subscriptions found"
          description={
            debouncedSearch || statusFilter || tierFilter || upcomingFilter
              ? "No subscriptions match your filters."
              : "No trainer subscriptions exist yet."
          }
        />
      )}

      {subscriptions.data && subscriptions.data.length > 0 && (
        <SubscriptionList
          subscriptions={subscriptions.data}
          onRowClick={handleRowClick}
        />
      )}

      <SubscriptionDetailDialog
        key={selectedSubId ?? "none"}
        subscriptionId={selectedSubId}
        open={detailOpen}
        onOpenChange={setDetailOpen}
      />
    </div>
  );
}
