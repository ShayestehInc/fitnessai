"use client";

import { useState, useRef, useCallback } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  DollarSign,
  TrendingUp,
  Users,
  UserCheck,
  Clock,
} from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { StatCard } from "@/components/dashboard/stat-card";
import { DataTable, type Column } from "@/components/shared/data-table";
import { useRevenueAnalytics } from "@/hooks/use-analytics";
import { RevenueChart } from "./revenue-chart";
import type {
  RevenuePeriod,
  RevenueSubscriber,
  RevenuePayment,
} from "@/types/analytics";

// ── Period selector (30d / 90d / 1y) ──

const REVENUE_PERIODS: RevenuePeriod[] = [30, 90, 365];

const PERIOD_LABELS: Record<RevenuePeriod, string> = {
  30: "30 days",
  90: "90 days",
  365: "1 year",
};

const PERIOD_SHORT_LABELS: Record<RevenuePeriod, string> = {
  30: "30d",
  90: "90d",
  365: "1y",
};

function RevenuePeriodSelector({
  value,
  onChange,
  disabled = false,
}: {
  value: RevenuePeriod;
  onChange: (days: RevenuePeriod) => void;
  disabled?: boolean;
}) {
  const groupRef = useRef<HTMLDivElement>(null);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (disabled) return;

      const currentIndex = REVENUE_PERIODS.indexOf(value);
      let nextIndex = currentIndex;

      if (e.key === "ArrowRight" || e.key === "ArrowDown") {
        e.preventDefault();
        nextIndex = (currentIndex + 1) % REVENUE_PERIODS.length;
      } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
        e.preventDefault();
        nextIndex =
          (currentIndex - 1 + REVENUE_PERIODS.length) %
          REVENUE_PERIODS.length;
      } else {
        return;
      }

      onChange(REVENUE_PERIODS[nextIndex]);
      const buttons =
        groupRef.current?.querySelectorAll<HTMLButtonElement>(
          '[role="radio"]',
        );
      buttons?.[nextIndex]?.focus();
    },
    [value, onChange, disabled],
  );

  return (
    <div
      ref={groupRef}
      className="flex gap-1"
      role="radiogroup"
      aria-label="Revenue time period"
      onKeyDown={handleKeyDown}
    >
      {REVENUE_PERIODS.map((days) => {
        const isActive = value === days;
        return (
          <button
            key={days}
            type="button"
            role="radio"
            aria-checked={isActive}
            aria-label={PERIOD_LABELS[days]}
            tabIndex={isActive ? 0 : -1}
            disabled={disabled}
            onClick={() => onChange(days)}
            className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:pointer-events-none disabled:opacity-50 ${
              isActive
                ? "bg-primary text-primary-foreground active:bg-primary/90"
                : "bg-muted text-muted-foreground hover:bg-accent hover:text-accent-foreground active:bg-accent/80"
            }`}
          >
            {PERIOD_SHORT_LABELS[days]}
          </button>
        );
      })}
    </div>
  );
}

// ── Currency formatting ──

const currencyFormatter = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
});

function formatCurrency(value: string | number): string {
  const num = typeof value === "string" ? parseFloat(value) : value;
  if (Number.isNaN(num)) return "$0.00";
  return currencyFormatter.format(num);
}

function formatRelativeDate(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

// ── Status badge helpers ──

const STATUS_STYLES: Record<string, string> = {
  succeeded:
    "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
  pending:
    "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
  failed: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  refunded:
    "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
  canceled:
    "bg-muted text-muted-foreground",
};

const PAYMENT_TYPE_LABELS: Record<string, string> = {
  subscription: "Subscription",
  one_time: "One-time",
};

function getRenewalColor(days: number | null): string {
  if (days === null) return "";
  if (days > 14) return "text-green-600 dark:text-green-400";
  if (days >= 7) return "text-amber-600 dark:text-amber-400";
  return "text-red-600 dark:text-red-400";
}

// ── Table columns ──

const subscriberColumns: Column<RevenueSubscriber>[] = [
  {
    key: "trainee_name",
    header: "Name",
    cell: (row) => (
      <span
        className="block max-w-[200px] truncate font-medium"
        title={row.trainee_name}
      >
        {row.trainee_name}
      </span>
    ),
  },
  {
    key: "amount",
    header: "Amount",
    cell: (row) => (
      <span>{formatCurrency(row.amount)}/mo</span>
    ),
  },
  {
    key: "days_until_renewal",
    header: "Renewal",
    cell: (row) => {
      if (row.days_until_renewal === null) {
        return <span aria-label="No renewal date">&mdash;</span>;
      }
      return (
        <span
          className={`inline-flex items-center gap-1 ${getRenewalColor(row.days_until_renewal)}`}
          aria-label={`${row.days_until_renewal} days until renewal`}
        >
          <Clock className="h-3.5 w-3.5" aria-hidden="true" />
          {row.days_until_renewal}d
        </span>
      );
    },
  },
  {
    key: "subscribed_since",
    header: "Since",
    cell: (row) => <span>{formatRelativeDate(row.subscribed_since)}</span>,
  },
];

const paymentColumns: Column<RevenuePayment>[] = [
  {
    key: "trainee_name",
    header: "Name",
    cell: (row) => (
      <span
        className="block max-w-[160px] truncate font-medium"
        title={row.trainee_name}
      >
        {row.trainee_name}
      </span>
    ),
  },
  {
    key: "payment_type",
    header: "Type",
    cell: (row) => (
      <span>{PAYMENT_TYPE_LABELS[row.payment_type] ?? row.payment_type}</span>
    ),
  },
  {
    key: "amount",
    header: "Amount",
    cell: (row) => <span>{formatCurrency(row.amount)}</span>,
  },
  {
    key: "status",
    header: "Status",
    cell: (row) => (
      <span
        className={`inline-block rounded-full px-2 py-0.5 text-xs font-medium ${STATUS_STYLES[row.status] ?? ""}`}
      >
        {row.status.charAt(0).toUpperCase() + row.status.slice(1)}
      </span>
    ),
  },
  {
    key: "paid_at",
    header: "Date",
    cell: (row) => (
      <span>
        {row.paid_at
          ? formatRelativeDate(row.paid_at)
          : formatRelativeDate(row.created_at)}
      </span>
    ),
  },
];

// ── Skeleton ──

function RevenueSkeleton() {
  return (
    <div
      className="space-y-6"
      role="status"
      aria-label="Loading revenue data"
    >
      <span className="sr-only">Loading revenue data...</span>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[0, 1, 2, 3].map((i) => (
          <Card key={i}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-4 w-4" />
            </CardHeader>
            <CardContent>
              <Skeleton className="h-8 w-20" />
            </CardContent>
          </Card>
        ))}
      </div>
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-40" />
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[240px] w-full" />
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-40" />
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <Skeleton className="h-10 w-full" />
            {[0, 1, 2].map((i) => (
              <Skeleton key={i} className="h-12 w-full" />
            ))}
          </div>
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-36" />
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <Skeleton className="h-10 w-full" />
            {[0, 1, 2].map((i) => (
              <Skeleton key={i} className="h-12 w-full" />
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ── Main component ──

export function RevenueSection() {
  const router = useRouter();
  const [days, setDays] = useState<RevenuePeriod>(30);
  const { data, isLoading, isError, isFetching, refetch } =
    useRevenueAnalytics(days);

  const totalRevenueParsed = data ? parseFloat(data.total_revenue) : 0;
  const isEmpty =
    data &&
    data.active_subscribers === 0 &&
    (Number.isNaN(totalRevenueParsed) || totalRevenueParsed === 0) &&
    data.recent_payments.length === 0;

  const hasData = data && !isEmpty;

  return (
    <section aria-labelledby="revenue-heading">
      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h2 id="revenue-heading" className="text-lg font-semibold">
          Revenue
        </h2>
        <RevenuePeriodSelector
          value={days}
          onChange={setDays}
          disabled={isLoading}
        />
      </div>

      {isLoading ? (
        <RevenueSkeleton />
      ) : isError ? (
        <ErrorState
          message="Failed to load revenue data"
          onRetry={() => refetch()}
        />
      ) : isEmpty ? (
        <EmptyState
          icon={DollarSign}
          title="No revenue data yet"
          description="Set up pricing to start accepting payments from your trainees."
          action={
            <Button asChild>
              <Link href="/subscription">Manage Pricing</Link>
            </Button>
          }
        />
      ) : hasData ? (
        <div
          className={`space-y-6 transition-opacity duration-200 ${isFetching ? "opacity-50" : "opacity-100"}`}
          aria-busy={isFetching}
        >
          {isFetching && (
            <div className="sr-only" role="status" aria-live="polite">
              Refreshing revenue data...
            </div>
          )}

          {/* Stat cards */}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatCard
              title="MRR"
              value={formatCurrency(data.mrr)}
              description="Monthly recurring revenue"
              icon={DollarSign}
            />
            <StatCard
              title={`Revenue (${PERIOD_SHORT_LABELS[days]})`}
              value={formatCurrency(data.total_revenue)}
              description={`Total in last ${PERIOD_LABELS[days]}`}
              icon={TrendingUp}
            />
            <StatCard
              title="Active Subscribers"
              value={data.active_subscribers}
              description="Currently subscribed trainees"
              icon={Users}
            />
            <StatCard
              title="Avg / Subscriber"
              value={formatCurrency(data.avg_revenue_per_subscriber)}
              description="Average monthly revenue"
              icon={UserCheck}
            />
          </div>

          {/* Monthly revenue chart */}
          <RevenueChart data={data.monthly_revenue} />

          {/* Subscribers table */}
          {data.subscribers.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">
                  Active Subscribers
                  <span className="ml-2 text-sm font-normal text-muted-foreground">
                    {data.subscribers.length} subscriber
                    {data.subscribers.length !== 1 ? "s" : ""}
                  </span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <DataTable
                  columns={subscriberColumns}
                  data={data.subscribers}
                  keyExtractor={(row) => row.trainee_id}
                  onRowClick={(row) =>
                    router.push(`/trainees/${row.trainee_id}`)
                  }
                  rowAriaLabel={(row) =>
                    `View ${row.trainee_name}'s profile`
                  }
                />
              </CardContent>
            </Card>
          )}

          {/* Recent payments table */}
          {data.recent_payments.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">
                  Recent Payments
                  <span className="ml-2 text-sm font-normal text-muted-foreground">
                    Last {data.recent_payments.length} payment
                    {data.recent_payments.length !== 1 ? "s" : ""}
                  </span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <DataTable
                  columns={paymentColumns}
                  data={data.recent_payments}
                  keyExtractor={(row) => row.id}
                />
              </CardContent>
            </Card>
          )}
        </div>
      ) : null}
    </section>
  );
}
