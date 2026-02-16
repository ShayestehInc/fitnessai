"use client";

import { format } from "date-fns";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import type { AdminTrainerListItem } from "@/types/admin";

interface TrainerListProps {
  trainers: AdminTrainerListItem[];
  onRowClick: (trainer: AdminTrainerListItem) => void;
}

const TIER_VARIANT: Record<string, string> = {
  FREE: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300",
  STARTER: "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300",
  PRO: "bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300",
  ENTERPRISE:
    "bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300",
};

const columns: Column<AdminTrainerListItem>[] = [
  {
    key: "name",
    header: "Name",
    cell: (row) => {
      const name =
        `${row.first_name} ${row.last_name}`.trim() || row.email;
      return (
        <div className="min-w-0">
          <p className="truncate font-medium">{name}</p>
          <p className="truncate text-xs text-muted-foreground">
            {row.email}
          </p>
        </div>
      );
    },
  },
  {
    key: "status",
    header: "Status",
    cell: (row) => (
      <Badge variant={row.is_active ? "default" : "secondary"}>
        {row.is_active ? "Active" : "Inactive"}
      </Badge>
    ),
  },
  {
    key: "tier",
    header: "Tier",
    cell: (row) => {
      const tier = row.subscription?.tier;
      if (!tier) return <span className="text-muted-foreground">None</span>;
      return (
        <Badge variant="secondary" className={TIER_VARIANT[tier] ?? ""}>
          {tier}
        </Badge>
      );
    },
  },
  {
    key: "trainees",
    header: "Trainees",
    cell: (row) => row.trainee_count,
  },
  {
    key: "created",
    header: "Joined",
    cell: (row) => format(new Date(row.created_at), "MMM d, yyyy"),
  },
];

export function TrainerList({ trainers, onRowClick }: TrainerListProps) {
  return (
    <DataTable
      columns={columns}
      data={trainers}
      keyExtractor={(row) => row.id}
      onRowClick={onRowClick}
    />
  );
}
