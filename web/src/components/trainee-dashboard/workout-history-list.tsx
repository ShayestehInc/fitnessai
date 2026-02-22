"use client";

import { useState, useCallback } from "react";
import Link from "next/link";
import { parseISO, format, isValid } from "date-fns";
import {
  Dumbbell,
  ChevronLeft,
  ChevronRight,
  Eye,
  Play,
} from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { useTraineeWorkoutHistory } from "@/hooks/use-trainee-dashboard";
import { WorkoutDetailDialog } from "./workout-detail-dialog";

function formatVolume(volume: number): string {
  return new Intl.NumberFormat("en-US").format(Math.round(volume));
}

export function WorkoutHistoryList() {
  const [page, setPage] = useState(1);
  const [detailId, setDetailId] = useState<number | null>(null);

  const { data, isLoading, isError, refetch } = useTraineeWorkoutHistory(page);

  const changePage = useCallback((newPage: number) => {
    setPage(newPage);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, []);

  if (isLoading) {
    return (
      <div className="space-y-3" aria-busy="true" aria-label="Loading workout history">
        {Array.from({ length: 5 }).map((_, i) => (
          <Skeleton key={i} className="h-20 w-full" />
        ))}
      </div>
    );
  }

  if (isError) {
    return (
      <ErrorState
        message="Failed to load workout history"
        onRetry={() => refetch()}
      />
    );
  }

  if (!data?.results?.length) {
    return (
      <EmptyState
        icon={Dumbbell}
        title="No workouts logged yet"
        description="Start your first workout to see it here."
        action={
          <Button size="sm" asChild>
            <Link href="/trainee/workout">
              <Play className="mr-1.5 h-4 w-4" aria-hidden="true" />
              Start Workout
            </Link>
          </Button>
        }
      />
    );
  }

  const totalCount = data.count ?? 0;
  const pageSize = 20;
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));

  return (
    <>
      <div className="space-y-3" aria-live="polite">
        {data.results.map((item) => (
          <Card key={item.id} className="transition-colors hover:bg-muted/30">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-base">
                  {item.workout_name}
                </CardTitle>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setDetailId(item.id)}
                  aria-label={`View details for ${item.workout_name} on ${item.date}`}
                >
                  <Eye className="mr-1.5 h-4 w-4" aria-hidden="true" />
                  Details
                </Button>
              </div>
              <p className="text-xs text-muted-foreground">
                {(() => {
                  const d = parseISO(item.date);
                  return isValid(d) ? format(d, "EEE, MMM d, yyyy") : item.date;
                })()}
              </p>
            </CardHeader>
            <CardContent className="pt-0">
              <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
                <span>
                  {item.exercise_count}{" "}
                  {item.exercise_count === 1 ? "exercise" : "exercises"}
                </span>
                <span>{item.total_sets} sets</span>
                {item.total_volume_lbs > 0 && (
                  <span>{formatVolume(item.total_volume_lbs)} lbs volume</span>
                )}
                {item.duration_display !== "0:00" && (
                  <span>{item.duration_display}</span>
                )}
              </div>
            </CardContent>
          </Card>
        ))}

        {/* Pagination */}
        {(data.previous || data.next) && (
          <nav
            className="flex items-center justify-between pt-2"
            aria-label="Workout history pagination"
          >
            <Button
              variant="outline"
              size="sm"
              disabled={!data.previous}
              onClick={() => changePage(Math.max(1, page - 1))}
              aria-label="Go to previous page"
            >
              <ChevronLeft className="mr-1 h-4 w-4" aria-hidden="true" />
              Previous
            </Button>
            <span className="text-sm text-muted-foreground">
              Page {page} of {totalPages}
            </span>
            <Button
              variant="outline"
              size="sm"
              disabled={!data.next}
              onClick={() => changePage(page + 1)}
              aria-label="Go to next page"
            >
              Next
              <ChevronRight className="ml-1 h-4 w-4" aria-hidden="true" />
            </Button>
          </nav>
        )}
      </div>

      {detailId !== null && (
        <WorkoutDetailDialog
          open
          onOpenChange={(open) => {
            if (!open) setDetailId(null);
          }}
          workoutId={detailId}
        />
      )}
    </>
  );
}
