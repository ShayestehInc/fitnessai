"use client";

import { useState, useMemo } from "react";
import { Users } from "lucide-react";
import { useAdminTrainers } from "@/hooks/use-admin-trainers";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { TrainerList } from "@/components/admin/trainer-list";
import { TrainerDetailDialog } from "@/components/admin/trainer-detail-dialog";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import type { AdminTrainerListItem } from "@/types/admin";

export default function AdminTrainersPage() {
  const [searchInput, setSearchInput] = useState("");
  const [activeFilter, setActiveFilter] = useState<boolean | undefined>(
    undefined,
  );
  const [selectedTrainer, setSelectedTrainer] =
    useState<AdminTrainerListItem | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);

  const debouncedSearch = useDebounce(searchInput, 300);

  const filters = useMemo(
    () => ({
      search: debouncedSearch || undefined,
      active: activeFilter,
    }),
    [debouncedSearch, activeFilter],
  );

  const trainers = useAdminTrainers(filters);

  function handleRowClick(trainer: AdminTrainerListItem) {
    setSelectedTrainer(trainer);
    setDialogOpen(true);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Trainers"
        description="Manage platform trainers"
      />

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <Input
          placeholder="Search by name or email..."
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          className="w-full sm:max-w-sm"
          aria-label="Search trainers"
        />
        <div className="flex gap-2" role="group" aria-label="Filter trainers by status">
          <Button
            variant={activeFilter === undefined ? "default" : "outline"}
            size="sm"
            className="min-h-[44px] sm:min-h-0"
            onClick={() => setActiveFilter(undefined)}
            aria-pressed={activeFilter === undefined}
          >
            All
          </Button>
          <Button
            variant={activeFilter === true ? "default" : "outline"}
            size="sm"
            className="min-h-[44px] sm:min-h-0"
            onClick={() => setActiveFilter(true)}
            aria-pressed={activeFilter === true}
          >
            Active
          </Button>
          <Button
            variant={activeFilter === false ? "default" : "outline"}
            size="sm"
            className="min-h-[44px] sm:min-h-0"
            onClick={() => setActiveFilter(false)}
            aria-pressed={activeFilter === false}
          >
            Inactive
          </Button>
        </div>
      </div>

      {trainers.isLoading && (
        <div className="space-y-2" role="status" aria-label="Loading trainers">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
          <span className="sr-only">Loading trainers...</span>
        </div>
      )}

      {trainers.isError && (
        <ErrorState
          message="Failed to load trainers"
          onRetry={() => trainers.refetch()}
        />
      )}

      {trainers.data && trainers.data.length === 0 && (
        <EmptyState
          icon={Users}
          title="No trainers found"
          description={
            debouncedSearch
              ? "No trainers match your search criteria."
              : "No trainers have joined the platform yet."
          }
        />
      )}

      {trainers.data && trainers.data.length > 0 && (
        <TrainerList
          trainers={trainers.data}
          onRowClick={handleRowClick}
        />
      )}

      <TrainerDetailDialog
        key={selectedTrainer?.id ?? "none"}
        trainer={selectedTrainer}
        open={dialogOpen}
        onOpenChange={(open) => {
          setDialogOpen(open);
          if (!open) setSelectedTrainer(null);
        }}
      />
    </div>
  );
}
