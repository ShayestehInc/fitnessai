"use client";

import { format } from "date-fns";
import { Loader2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import { formatCurrency } from "@/lib/format-utils";
import type {
  AdminPaymentHistory,
  AdminSubscriptionChange,
} from "@/types/admin";

const paymentColumns: Column<AdminPaymentHistory>[] = [
  {
    key: "date",
    header: "Date",
    cell: (row) => format(new Date(row.payment_date), "MMM d, yyyy"),
  },
  {
    key: "amount",
    header: "Amount",
    cell: (row) => formatCurrency(row.amount),
  },
  {
    key: "status",
    header: "Status",
    cell: (row) => (
      <Badge variant={row.status === "succeeded" ? "default" : "destructive"}>
        {row.status}
      </Badge>
    ),
  },
  {
    key: "description",
    header: "Description",
    cell: (row) => row.description || "--",
  },
];

interface PaymentHistoryTabProps {
  payments: AdminPaymentHistory[] | undefined;
  isLoading: boolean;
}

export function PaymentHistoryTab({
  payments,
  isLoading,
}: PaymentHistoryTabProps) {
  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-4" role="status" aria-label="Loading payment history">
        <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" aria-hidden="true" />
        <span className="sr-only">Loading payment history...</span>
      </div>
    );
  }

  if (!payments || payments.length === 0) {
    return (
      <p className="py-4 text-center text-sm text-muted-foreground">No payment history</p>
    );
  }

  return (
    <DataTable
      columns={paymentColumns}
      data={payments}
      keyExtractor={(row) => row.id}
    />
  );
}

const changeColumns: Column<AdminSubscriptionChange>[] = [
  {
    key: "date",
    header: "Date",
    cell: (row) => format(new Date(row.created_at), "MMM d, yyyy HH:mm"),
  },
  {
    key: "type",
    header: "Type",
    cell: (row) => <Badge variant="outline">{row.change_type}</Badge>,
  },
  {
    key: "details",
    header: "Details",
    cell: (row) => {
      if (row.from_tier && row.to_tier)
        return (
          <span>
            {row.from_tier} <span aria-label="changed to">&rarr;</span> {row.to_tier}
          </span>
        );
      if (row.from_status && row.to_status)
        return (
          <span>
            {row.from_status} <span aria-label="changed to">&rarr;</span> {row.to_status}
          </span>
        );
      return "--";
    },
  },
  {
    key: "by",
    header: "By",
    cell: (row) => row.changed_by_email || "System",
  },
  {
    key: "reason",
    header: "Reason",
    cell: (row) => row.reason || "--",
  },
];

interface ChangeHistoryTabProps {
  changes: AdminSubscriptionChange[] | undefined;
  isLoading: boolean;
}

export function ChangeHistoryTab({
  changes,
  isLoading,
}: ChangeHistoryTabProps) {
  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-4" role="status" aria-label="Loading change history">
        <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" aria-hidden="true" />
        <span className="sr-only">Loading change history...</span>
      </div>
    );
  }

  if (!changes || changes.length === 0) {
    return (
      <p className="py-4 text-center text-sm text-muted-foreground">No change history</p>
    );
  }

  return (
    <DataTable
      columns={changeColumns}
      data={changes}
      keyExtractor={(row) => row.id}
    />
  );
}
