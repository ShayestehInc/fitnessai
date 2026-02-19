"use client";

import { useState } from "react";
import { useExercises } from "@/hooks/use-exercises";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { ExerciseList } from "@/components/exercises/exercise-list";
import { ExerciseGridSkeleton } from "@/components/exercises/exercise-grid-skeleton";
import type { MuscleGroup } from "@/types/program";

export default function ExercisesPage() {
  const [search, setSearch] = useState("");
  const [muscleGroup, setMuscleGroup] = useState<MuscleGroup | "">("");
  const debouncedSearch = useDebounce(search, 300);

  const { data, isLoading, isError, refetch } = useExercises(
    debouncedSearch,
    muscleGroup,
  );

  if (isLoading) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title="Exercise Bank" description="Browse and manage exercises" />
          <ExerciseGridSkeleton />
        </div>
      </PageTransition>
    );
  }

  if (isError) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title="Exercise Bank" description="Browse and manage exercises" />
          <ErrorState message="Failed to load exercises" onRetry={() => refetch()} />
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader title="Exercise Bank" description="Browse and manage exercises" />
        <ExerciseList
          exercises={data?.results ?? []}
          searchValue={search}
          onSearchChange={setSearch}
          muscleGroup={muscleGroup}
          onMuscleGroupChange={setMuscleGroup}
        />
      </div>
    </PageTransition>
  );
}
