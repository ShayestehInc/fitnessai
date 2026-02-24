"use client";

import { useState, useDeferredValue } from "react";
import Link from "next/link";
import { Dumbbell, Plus, Search, Sparkles } from "lucide-react";
import { usePrograms } from "@/hooks/use-programs";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ProgramList } from "@/components/programs/program-list";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function ProgramsPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const deferredSearch = useDeferredValue(search);
  const { data, isLoading, isError, refetch } = usePrograms(
    page,
    deferredSearch,
  );

  const isEmpty = data && data.results.length === 0 && page === 1 && !deferredSearch;
  const noResults = data && data.results.length === 0 && (page > 1 || Boolean(deferredSearch));

  return (
    <div className="space-y-6">
      <PageHeader
        title="Programs"
        description="Create and manage workout program templates"
        actions={
          <div className="flex flex-wrap gap-2">
            <Button variant="outline" asChild>
              <Link href="/programs/generate">
                <Sparkles className="mr-2 h-4 w-4" aria-hidden="true" />
                Generate with AI
              </Link>
            </Button>
            <Button asChild>
              <Link href="/programs/new">
                <Plus className="mr-2 h-4 w-4" aria-hidden="true" />
                Create Program
              </Link>
            </Button>
          </div>
        }
      />

      {!isEmpty && !isLoading && (
        <div className="relative max-w-sm">
          <Search
            className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"
            aria-hidden="true"
          />
          <Input
            placeholder="Search programs..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="pl-9"
            maxLength={100}
            aria-label="Search programs"
          />
        </div>
      )}

      {isLoading ? (
        <LoadingSpinner />
      ) : isError ? (
        <ErrorState
          message="Failed to load programs"
          onRetry={() => refetch()}
        />
      ) : isEmpty ? (
        <EmptyState
          icon={Dumbbell}
          title="No program templates yet"
          description="Create your first program to get started."
          action={
            <Button asChild>
              <Link href="/programs/new">
                <Plus className="mr-2 h-4 w-4" aria-hidden="true" />
                Create Program
              </Link>
            </Button>
          }
        />
      ) : noResults ? (
        <EmptyState
          icon={Search}
          title="No programs found"
          description="Try adjusting your search term."
        />
      ) : data ? (
        <ProgramList
          programs={data.results}
          totalCount={data.count}
          page={page}
          onPageChange={setPage}
        />
      ) : null}
    </div>
  );
}
