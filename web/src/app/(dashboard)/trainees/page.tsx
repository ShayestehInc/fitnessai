"use client";

import { useState } from "react";
import Link from "next/link";
import { Users } from "lucide-react";
import { useTrainees } from "@/hooks/use-trainees";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import { ExportButton } from "@/components/shared/export-button";
import { API_URLS } from "@/lib/constants";
import { TraineeSearch } from "@/components/trainees/trainee-search";
import { TraineeTable } from "@/components/trainees/trainee-table";
import { TraineeTableSkeleton } from "@/components/trainees/trainee-table-skeleton";

export default function TraineesPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const debouncedSearch = useDebounce(search, 300);

  const { data, isLoading, isError, refetch } = useTrainees(
    page,
    debouncedSearch,
  );

  function handleSearchChange(value: string) {
    setSearch(value);
    setPage(1);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Trainees"
        description="Manage your training clients"
        actions={
          <div className="flex items-center gap-2">
            {data && data.results.length > 0 && (
              <ExportButton
                url={API_URLS.EXPORT_TRAINEES}
                filename={`trainees_${new Date().toISOString().slice(0, 10)}.csv`}
                label="Export CSV"
                aria-label="Export trainees as CSV"
              />
            )}
            <Button asChild>
              <Link href="/invitations">Invite Trainee</Link>
            </Button>
          </div>
        }
      />
      <TraineeSearch value={search} onChange={handleSearchChange} />
      {isLoading ? (
        <TraineeTableSkeleton />
      ) : isError ? (
        <ErrorState message="Failed to load trainees" onRetry={() => refetch()} />
      ) : data && data.results.length === 0 && !debouncedSearch ? (
        <EmptyState
          icon={Users}
          title="No trainees yet"
          description="Send an invitation to get your first trainee started."
          action={
            <Button asChild>
              <Link href="/invitations">Send Invitation</Link>
            </Button>
          }
        />
      ) : data && data.results.length === 0 && debouncedSearch ? (
        <EmptyState
          icon={Users}
          title="No results"
          description={`No trainees match "${debouncedSearch}"`}
          action={
            <Button
              variant="outline"
              onClick={() => {
                setSearch("");
                setPage(1);
              }}
            >
              Clear search
            </Button>
          }
        />
      ) : data ? (
        <TraineeTable
          trainees={data.results}
          totalCount={data.count}
          page={page}
          onPageChange={setPage}
        />
      ) : null}
    </div>
  );
}
