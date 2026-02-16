"use client";

import { format } from "date-fns";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import type { AdminSubscriptionListItem } from "@/types/admin";

interface SubscriptionListProps {
  subscriptions: AdminSubscriptionListItem[];
  onRowClick: (sub: AdminSubscriptionListItem) => void;
}

const STATUS_VARIANT: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
  active: "default",
  past_due: "destructive",
  canceled: "secondary",
  trialing: "outline",
  suspended: "secondary",
};

const TIER_COLORS: Record<string, string> = {
  FREE: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300",
  STARTER: "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300",
  PRO: "bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300",
  ENTERPRISE:
    "bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300",
};

function formatCurrency(value: string): string {
  const num = parseFloat(value);
  if (isNaN(num)) return "$0.00";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(num);
}

const columns: Column<AdminSubscriptionListItem>[] = [
  {
    key: "trainer",
    header: "Trainer",
    cell: (row) => (
      <div className="min-w-0">
        <p className="truncate font-medium">{row.trainer_name}</p>
        <p className="truncate text-xs text-muted-foreground">
          {row.trainer_email}
        </p>
      </div>
    ),
  },
  {
    key: "tier",
    header: "Tier",
    cell: (row) => (
      <Badge variant="secondary" className={TIER_COLORS[row.tier] ?? ""}>
        {row.tier}
      </Badge>
    ),
  },
  {
    key: "status",
    header: "Status",
    cell: (row) => (
      <Badge variant={STATUS_VARIANT[row.status] ?? "secondary"}>
        {row.status.replace("_", " ").charAt(0).toUpperCase() +
          row.status.replace("_", " ").slice(1)}
        <span className="sr-only"> status</span>
      </Badge>
    ),
  },
  {
    key: "price",
    header: "Price",
    cell: (row) => `${formatCurrency(row.monthly_price)}/mo`,
  },
  {
    key: "next_payment",
    header: "Next Payment",
    cell: (row) =>
      row.next_payment_date
        ? format(new Date(row.next_payment_date), "MMM d, yyyy")
        : "N/A",
  },
  {
    key: "past_due",
    header: "Past Due",
    cell: (row) => {
      const amount = parseFloat(row.past_due_amount);
      if (amount <= 0) return <span className="text-muted-foreground">--</span>;
      return (
        <span className="font-medium text-destructive">
          {formatCurrency(row.past_due_amount)}
        </span>
      );
    },
  },
];

export function SubscriptionList({
  subscriptions,
  onRowClick,
}: SubscriptionListProps) {
  return (
    <DataTable
      columns={columns}
      data={subscriptions}
      keyExtractor={(row) => row.id}
      onRowClick={onRowClick}
    />
  );
}
