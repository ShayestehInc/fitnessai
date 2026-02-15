"use client";

import { useState } from "react";
import { ChevronLeft, ChevronRight, Mail } from "lucide-react";
import { useInvitations } from "@/hooks/use-invitations";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { Button } from "@/components/ui/button";
import { InvitationTable } from "@/components/invitations/invitation-table";
import { CreateInvitationDialog } from "@/components/invitations/create-invitation-dialog";

export default function InvitationsPage() {
  const [page, setPage] = useState(1);
  const { data, isLoading, isError, refetch } = useInvitations(page);

  const hasNextPage = Boolean(data?.next);
  const hasPrevPage = page > 1;

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
      ) : data && data.results.length === 0 && page === 1 ? (
        <EmptyState
          icon={Mail}
          title="No invitations yet"
          description="Send your first invitation to start onboarding trainees."
          action={<CreateInvitationDialog />}
        />
      ) : data ? (
        <>
          <InvitationTable invitations={data.results} />
          {(hasPrevPage || hasNextPage) && (
            <nav className="flex items-center justify-between" aria-label="Invitation pagination">
              <Button
                variant="outline"
                size="sm"
                disabled={!hasPrevPage}
                onClick={() => setPage((p) => p - 1)}
                aria-label="Go to previous page"
              >
                <ChevronLeft className="mr-1 h-4 w-4" aria-hidden="true" />
                Previous
              </Button>
              <span className="text-sm text-muted-foreground" aria-current="page">
                Page {page}
              </span>
              <Button
                variant="outline"
                size="sm"
                disabled={!hasNextPage}
                onClick={() => setPage((p) => p + 1)}
                aria-label="Go to next page"
              >
                Next
                <ChevronRight className="ml-1 h-4 w-4" aria-hidden="true" />
              </Button>
            </nav>
          )}
        </>
      ) : null}
    </div>
  );
}
