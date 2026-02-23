"use client";

import { useState, useCallback, useEffect, useRef, useMemo } from "react";
import { Loader2 } from "lucide-react";
import { useExercises } from "@/hooks/use-exercises";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { ExerciseList } from "@/components/exercises/exercise-list";
import { ExerciseGridSkeleton } from "@/components/exercises/exercise-grid-skeleton";
import type { MuscleGroup, DifficultyLevel, GoalType } from "@/types/program";

export default function ExercisesPage() {
  const [search, setSearch] = useState("");
  const [muscleGroup, setMuscleGroup] = useState<MuscleGroup | "">("");
  const [difficultyLevel, setDifficultyLevel] = useState<DifficultyLevel | "">("");
  const [goal, setGoal] = useState<GoalType | "">("");
  const debouncedSearch = useDebounce(search, 300);

  const {
    data,
    isLoading,
    isError,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useExercises(debouncedSearch, muscleGroup, difficultyLevel, goal);

  // Flatten all pages into a single array
  const exercises = useMemo(
    () => data?.pages.flatMap((page) => page.results) ?? [],
    [data],
  );
  const totalCount = data?.pages[0]?.count ?? 0;

  // Infinite scroll: observe a sentinel element near the bottom
  const sentinelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const sentinel = sentinelRef.current;
    if (!sentinel) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && hasNextPage && !isFetchingNextPage) {
          fetchNextPage();
        }
      },
      { rootMargin: "400px" },
    );

    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [hasNextPage, isFetchingNextPage, fetchNextPage]);

  const handleSearchChange = useCallback((value: string) => {
    setSearch(value);
  }, []);

  const handleMuscleGroupChange = useCallback((mg: MuscleGroup | "") => {
    setMuscleGroup(mg);
  }, []);

  const handleDifficultyChange = useCallback((dl: DifficultyLevel | "") => {
    setDifficultyLevel(dl);
  }, []);

  const handleGoalChange = useCallback((g: GoalType | "") => {
    setGoal(g);
  }, []);

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
        <PageHeader
          title="Exercise Bank"
          description={
            totalCount > 0
              ? `${totalCount} exercises available`
              : "Browse and manage exercises"
          }
        />
        <ExerciseList
          exercises={exercises}
          searchValue={search}
          onSearchChange={handleSearchChange}
          muscleGroup={muscleGroup}
          onMuscleGroupChange={handleMuscleGroupChange}
          difficultyLevel={difficultyLevel}
          onDifficultyChange={handleDifficultyChange}
          goal={goal}
          onGoalChange={handleGoalChange}
        />
        {/* Infinite scroll sentinel */}
        <div ref={sentinelRef} />
        {isFetchingNextPage && (
          <div className="flex justify-center py-4">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        )}
        {!hasNextPage && exercises.length > 0 && (
          <p className="pb-4 text-center text-sm text-muted-foreground">
            Showing all {totalCount} exercises
          </p>
        )}
      </div>
    </PageTransition>
  );
}
