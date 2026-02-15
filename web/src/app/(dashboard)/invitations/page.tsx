"use client";

import { Mail } from "lucide-react";
import { useInvitations } from "@/hooks/use-invitations";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { InvitationTable } from "@/components/invitations/invitation-table";
import { CreateInvitationDialog } from "@/components/invitations/create-invitation-dialog";

export default function InvitationsPage() {
  const { data, isLoading, isError, refetch } = useInvitations();

  return (
    <div className="space-y-6">
      <PageHeader
        title="Invitations"
        description="Manage trainee invitations"
        actions={<CreateInvitationDialog />}
      />

      {isLoading ? (
        <LoadingSpinner />
      ) : isError ? (
        <ErrorState
          message="Failed to load invitations"
          onRetry={() => refetch()}
        />
      ) : data && data.results.length === 0 ? (
        <EmptyState
          icon={Mail}
          title="No invitations yet"
          description="Send your first invitation to start onboarding trainees."
          action={<CreateInvitationDialog />}
        />
      ) : data ? (
        <InvitationTable invitations={data.results} />
      ) : null}
    </div>
  );
}
