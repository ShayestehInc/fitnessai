"use client";

import { Loader2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import type { AdminSubscriptionTier } from "@/types/admin";
import { formatCurrency } from "@/lib/format-utils";

interface TierListProps {
  tiers: AdminSubscriptionTier[];
  onEdit: (tier: AdminSubscriptionTier) => void;
  onToggleActive: (id: number) => void;
  onDelete: (tier: AdminSubscriptionTier) => void;
  togglingId: number | null;
}

export function TierList({
  tiers,
  onEdit,
  onToggleActive,
  onDelete,
  togglingId,
}: TierListProps) {
  const columns: Column<AdminSubscriptionTier>[] = [
    {
      key: "name",
      header: "Name",
      cell: (row) => (
        <div>
          <p className="font-medium">{row.display_name}</p>
          <p className="text-xs text-muted-foreground">{row.name}</p>
        </div>
      ),
    },
    {
      key: "price",
      header: "Price",
      cell: (row) => `${formatCurrency(row.price)}/mo`,
    },
    {
      key: "limit",
      header: "Trainee Limit",
      className: "hidden md:table-cell",
      cell: (row) => row.trainee_limit_display,
    },
    {
      key: "active",
      header: "Active",
      cell: (row) => (
        <Button
          variant="ghost"
          size="sm"
          onClick={(e) => {
            e.stopPropagation();
            onToggleActive(row.id);
          }}
          disabled={togglingId === row.id}
          aria-label={`Toggle ${row.display_name} active status`}
        >
          {togglingId === row.id ? (
            <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
          ) : (
            <Badge variant={row.is_active ? "default" : "secondary"}>
              {row.is_active ? "Active" : "Inactive"}
            </Badge>
          )}
        </Button>
      ),
    },
    {
      key: "sort",
      header: "Order",
      className: "hidden md:table-cell",
      cell: (row) => row.sort_order,
    },
    {
      key: "actions",
      header: "Actions",
      cell: (row) => (
        <div className="flex flex-col gap-1 sm:flex-row">
          <Button
            variant="ghost"
            size="sm"
            onClick={(e) => {
              e.stopPropagation();
              onEdit(row);
            }}
          >
            Edit
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="text-destructive hover:text-destructive"
            onClick={(e) => {
              e.stopPropagation();
              onDelete(row);
            }}
          >
            Delete
          </Button>
        </div>
      ),
    },
  ];

  return (
    <DataTable
      columns={columns}
      data={tiers}
      keyExtractor={(row) => row.id}
    />
  );
}
