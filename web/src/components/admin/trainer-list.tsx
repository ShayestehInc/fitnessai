"use client";

import { format } from "date-fns";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import { TIER_COLORS } from "@/types/admin";
import type { AdminTrainerListItem } from "@/types/admin";

interface TrainerListProps {
  trainers: AdminTrainerListItem[];
  onRowClick: (trainer: AdminTrainerListItem) => void;
}

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
        <Badge variant="secondary" className={TIER_COLORS[tier] ?? ""}>
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
