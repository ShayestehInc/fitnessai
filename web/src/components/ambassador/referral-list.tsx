"use client";

import { useState } from "react";
import { format } from "date-fns";
import { Search, Users, ChevronLeft, ChevronRight } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { useAmbassadorReferrals } from "@/hooks/use-ambassador";
import { formatCurrency } from "@/lib/format-utils";
import type { AmbassadorSelfReferral } from "@/types/ambassador";

const STATUS_TABS = [
  { label: "All", value: "" },
  { label: "Active", value: "active" },
  { label: "Pending", value: "pending" },
  { label: "Churned", value: "churned" },
] as const;

const PAGE_SIZE = 20;

function ReferralCard({ referral }: { referral: AmbassadorSelfReferral }) {
  return (
    <div className="flex items-center justify-between gap-4 rounded-lg border p-4">
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium">
          {`${referral.trainer.first_name} ${referral.trainer.last_name}`.trim() ||
            referral.trainer.email}
        </p>
        <div className="mt-1 flex items-center gap-3 text-xs text-muted-foreground">
          <span>{referral.trainer.email}</span>
          {referral.referred_at && (
            <span>
              {format(new Date(referral.referred_at), "MMM d, yyyy")}
            </span>
          )}
        </div>
      </div>
      <div className="flex items-center gap-3">
        {referral.total_commission_earned !== undefined && (
          <span className="text-sm font-medium text-green-600 dark:text-green-400">
            {formatCurrency(referral.total_commission_earned)}
          </span>
        )}
        <StatusBadge status={referral.status} />
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const variant =
    status === "active"
      ? "default"
      : status === "pending"
        ? "secondary"
        : "outline";
  return (
    <Badge variant={variant}>
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </Badge>
  );
}

function ReferralListSkeleton() {
  return (
    <div className="space-y-3">
      {[1, 2, 3, 4].map((i) => (
        <Skeleton key={i} className="h-16 w-full" />
      ))}
    </div>
  );
}

export function ReferralList() {
  const [statusFilter, setStatusFilter] = useState("");
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");

  const { data, isLoading, isFetching, isError } = useAmbassadorReferrals(
    statusFilter,
    page,
  );

  const referrals = data?.results ?? [];
  const totalCount = data?.count ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));
  const hasNext = data?.next != null;
  const hasPrevious = data?.previous != null;

  // Client-side search within current page results
  const filtered = search
    ? referrals.filter(
        (r) =>
          `${r.trainer.first_name} ${r.trainer.last_name}`
            .toLowerCase()
            .includes(search.toLowerCase()) ||
          r.trainer.email.toLowerCase().includes(search.toLowerCase()),
      )
    : referrals;

  function handleStatusChange(newStatus: string) {
    setStatusFilter(newStatus);
    setPage(1);
    setSearch("");
  }

  if (isLoading) {
    return (
      <div className="space-y-4">
        {/* Tab skeleton */}
        <div className="flex gap-2">
          {STATUS_TABS.map((tab) => (
            <Skeleton key={tab.value} className="h-9 w-20 rounded-md" />
          ))}
        </div>
        <Skeleton className="h-10 w-full sm:max-w-sm" />
        <ReferralListSkeleton />
      </div>
    );
  }

  const noReferralsAtAll = !statusFilter && totalCount === 0;
  const noFilterResults = statusFilter && totalCount === 0;

  return (
    <div className="space-y-4">
      {/* Status filter tabs */}
      <div className="flex flex-wrap gap-2" role="tablist" aria-label="Filter referrals by status">
        {STATUS_TABS.map((tab) => (
          <Button
            key={tab.value}
            role="tab"
            aria-selected={statusFilter === tab.value}
            variant={statusFilter === tab.value ? "default" : "outline"}
            size="sm"
            onClick={() => handleStatusChange(tab.value)}
          >
            {tab.label}
          </Button>
        ))}
      </div>

      {/* Search */}
      <div className="relative sm:max-w-sm">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search within results..."
          className="pl-9"
        />
      </div>

      {/* Error state */}
      {isError && (
        <EmptyState
          icon={Users}
          title="Failed to load referrals"
          description="Something went wrong. Please try again."
        />
      )}

      {/* Content */}
      {!isError && (
        <>
          {noReferralsAtAll ? (
            <EmptyState
              icon={Users}
              title="No referrals yet"
              description="Share your referral code to start earning commissions."
            />
          ) : noFilterResults ? (
            <EmptyState
              icon={Users}
              title="No referrals match this filter"
              description="Try selecting a different status filter."
            />
          ) : filtered.length === 0 && search ? (
            <EmptyState
              icon={Users}
              title="No referrals match your search"
              description="Try adjusting your search query."
            />
          ) : (
            <div
              className="space-y-3 transition-opacity"
              style={{ opacity: isFetching ? 0.5 : 1 }}
            >
              {filtered.map((ref) => (
                <ReferralCard key={ref.id} referral={ref} />
              ))}
            </div>
          )}

          {/* Pagination controls */}
          {totalPages > 1 && (
            <nav
              className="flex items-center justify-between border-t pt-4"
              aria-label="Referral list pagination"
            >
              <p className="text-sm text-muted-foreground">
                Page {page} of {totalPages} ({totalCount} referrals)
              </p>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={!hasPrevious}
                  aria-label="Previous page"
                >
                  <ChevronLeft className="mr-1 h-4 w-4" />
                  Previous
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setPage((p) => p + 1)}
                  disabled={!hasNext}
                  aria-label="Next page"
                >
                  Next
                  <ChevronRight className="ml-1 h-4 w-4" />
                </Button>
              </div>
            </nav>
          )}
        </>
      )}
    </div>
  );
}
