"use client";

import { format } from "date-fns";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import {
  TIER_COLORS,
  SUBSCRIPTION_STATUS_VARIANT,
} from "@/lib/admin-constants";
import type { AdminSubscriptionListItem } from "@/types/admin";
import { formatCurrency } from "@/lib/format-utils";

interface SubscriptionListProps {
  subscriptions: AdminSubscriptionListItem[];
  onRowClick: (sub: AdminSubscriptionListItem) => void;
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
    cell: (row) => {
      const label = row.status
        .replace(/_/g, " ")
        .replace(/\b\w/g, (c) => c.toUpperCase());
      return (
        <Badge
          variant={SUBSCRIPTION_STATUS_VARIANT[row.status] ?? "secondary"}
        >
          {label}
          <span className="sr-only"> status</span>
        </Badge>
      );
    },
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
