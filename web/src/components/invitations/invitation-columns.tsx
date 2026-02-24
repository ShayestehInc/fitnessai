import { format } from "date-fns";
import type { Column } from "@/components/shared/data-table";
import type { Invitation } from "@/types/invitation";
import { InvitationStatusBadge } from "./invitation-status-badge";
import { InvitationActions } from "./invitation-actions";

export const invitationColumns: Column<Invitation>[] = [
  {
    key: "email",
    header: "Email",
    cell: (row) => (
      <span className="block max-w-[200px] truncate font-medium" title={row.email}>
        {row.email}
      </span>
    ),
  },
  {
    key: "status",
    header: "Status",
    cell: (row) => (
      <InvitationStatusBadge status={row.status} isExpired={row.is_expired} />
    ),
  },
  {
    key: "program",
    header: "Program",
    className: "hidden md:table-cell",
    cell: (row) => (
      <span className="text-sm text-muted-foreground">
        {row.program_template_name ?? "None"}
      </span>
    ),
  },
  {
    key: "sent",
    header: "Sent",
    cell: (row) => (
      <span className="text-sm text-muted-foreground">
        {format(new Date(row.created_at), "MMM d, yyyy")}
      </span>
    ),
  },
  {
    key: "expires",
    header: "Expires",
    className: "hidden md:table-cell",
    cell: (row) => (
      <span className="text-sm text-muted-foreground">
        {format(new Date(row.expires_at), "MMM d, yyyy")}
      </span>
    ),
  },
  {
    key: "actions",
    header: "",
    className: "w-12",
    cell: (row) => <InvitationActions invitation={row} />,
  },
];
