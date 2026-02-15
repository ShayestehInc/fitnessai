import Link from "next/link";
import { format } from "date-fns";
import { Badge } from "@/components/ui/badge";
import type { Column } from "@/components/shared/data-table";
import type { TraineeListItem } from "@/types/trainer";

export const traineeColumns: Column<TraineeListItem>[] = [
  {
    key: "name",
    header: "Name",
    cell: (row) => (
      <div>
        <Link
          href={`/trainees/${row.id}`}
          className="font-medium hover:underline"
        >
          {row.first_name} {row.last_name}
        </Link>
        <p className="text-xs text-muted-foreground">{row.email}</p>
      </div>
    ),
  },
  {
    key: "status",
    header: "Status",
    cell: (row) => (
      <Badge variant={row.profile_complete ? "default" : "secondary"}>
        {row.profile_complete ? "Active" : "Onboarding"}
      </Badge>
    ),
  },
  {
    key: "last_activity",
    header: "Last Activity",
    cell: (row) => (
      <span className="text-sm text-muted-foreground">
        {row.last_activity
          ? format(new Date(row.last_activity), "MMM d, yyyy")
          : "Never"}
      </span>
    ),
  },
  {
    key: "program",
    header: "Program",
    cell: (row) => (
      <span className="text-sm text-muted-foreground">
        {row.current_program?.name ?? "None"}
      </span>
    ),
  },
  {
    key: "joined",
    header: "Joined",
    cell: (row) => (
      <span className="text-sm text-muted-foreground">
        {format(new Date(row.created_at), "MMM d, yyyy")}
      </span>
    ),
  },
];
