"use client";

import { format } from "date-fns";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import type { AdminUser } from "@/types/admin";

interface UserListProps {
  users: AdminUser[];
  onRowClick: (user: AdminUser) => void;
}

const columns: Column<AdminUser>[] = [
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
    key: "role",
    header: "Role",
    cell: (row) => (
      <Badge variant={row.role === "ADMIN" ? "default" : "outline"}>
        {row.role}
      </Badge>
    ),
  },
  {
    key: "active",
    header: "Status",
    cell: (row) => (
      <Badge variant={row.is_active ? "default" : "secondary"}>
        {row.is_active ? "Active" : "Inactive"}
      </Badge>
    ),
  },
  {
    key: "trainees",
    header: "Trainees",
    className: "hidden md:table-cell",
    cell: (row) =>
      row.role === "TRAINER" ? row.trainee_count : "--",
  },
  {
    key: "created",
    header: "Created",
    className: "hidden md:table-cell",
    cell: (row) => format(new Date(row.created_at), "MMM d, yyyy"),
  },
];

export function UserList({ users, onRowClick }: UserListProps) {
  return (
    <DataTable
      columns={columns}
      data={users}
      keyExtractor={(row) => row.id}
      onRowClick={onRowClick}
    />
  );
}
