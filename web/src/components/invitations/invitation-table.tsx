"use client";

import { DataTable } from "@/components/shared/data-table";
import { invitationColumns } from "./invitation-columns";
import type { Invitation } from "@/types/invitation";

interface InvitationTableProps {
  invitations: Invitation[];
}

export function InvitationTable({ invitations }: InvitationTableProps) {
  return (
    <DataTable
      columns={invitationColumns}
      data={invitations}
      keyExtractor={(row) => row.id}
    />
  );
}
