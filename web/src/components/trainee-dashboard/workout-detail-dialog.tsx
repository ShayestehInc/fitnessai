"use client";

import { Check, X, Clock } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { useTraineeWorkoutDetail } from "@/hooks/use-trainee-dashboard";
import type { WorkoutData, WorkoutExerciseLog } from "@/types/trainee-dashboard";

interface WorkoutDetailDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  workoutId: number;
}

function getExercises(workoutData: WorkoutData | undefined): WorkoutExerciseLog[] {
  if (!workoutData) return [];
  // Direct exercises array
  if (workoutData.exercises?.length) return workoutData.exercises;
  // Sessions format (from mobile app)
  if (workoutData.sessions?.length) {
    const first = workoutData.sessions[0];
    if (first?.exercises?.length) return first.exercises;
  }
  return [];
}

function getWorkoutName(workoutData: WorkoutData | undefined): string {
  if (!workoutData) return "Workout";
  if (workoutData.workout_name) return workoutData.workout_name;
  // Sessions format (from mobile app)
  if (workoutData.sessions?.length) {
    const first = workoutData.sessions[0];
    if (first?.workout_name) return first.workout_name;
  }
  return "Workout";
}

function getDuration(workoutData: WorkoutData | undefined): string | null {
  if (!workoutData) return null;
  if (workoutData.duration) return workoutData.duration;
  if (workoutData.sessions?.length) {
    const first = workoutData.sessions[0];
    if (first?.duration) return first.duration;
  }
  return null;
}

export function WorkoutDetailDialog({
  open,
  onOpenChange,
  workoutId,
}: WorkoutDetailDialogProps) {
  const { data, isLoading, isError, refetch } =
    useTraineeWorkoutDetail(workoutId);

  const workoutData = data?.workout_data;
  const exercises = getExercises(workoutData);
  const workoutName = getWorkoutName(workoutData);
  const duration = getDuration(workoutData);
  const dateFormatted = data?.date
    ? new Date(data.date).toLocaleDateString(undefined, {
        weekday: "long",
        month: "short",
        day: "numeric",
        year: "numeric",
      })
    : "";

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-h-[80vh] sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>{workoutName}</DialogTitle>
          <DialogDescription>
            {dateFormatted}
            {duration && duration !== "00:00" && (
              <span className="ml-2 inline-flex items-center gap-1">
                <Clock className="inline h-3 w-3" aria-hidden="true" />
                {duration}
              </span>
            )}
          </DialogDescription>
        </DialogHeader>

        {isLoading && (
          <div className="space-y-4 py-4" aria-busy="true" aria-label="Loading workout details">
            {Array.from({ length: 3 }).map((_, i) => (
              <Skeleton key={i} className="h-24 w-full" />
            ))}
          </div>
        )}

        {isError && (
          <div className="py-4">
            <ErrorState
              message="Failed to load workout details"
              onRetry={() => refetch()}
            />
          </div>
        )}

        {data && exercises.length === 0 && (
          <p className="py-8 text-center text-sm text-muted-foreground" role="status">
            No exercise data recorded for this workout.
          </p>
        )}

        {data && exercises.length > 0 && (
          <div className="space-y-4 py-2">
            {exercises.map((ex, i) => (
              <div
                key={`${ex.exercise_id}-${i}`}
                className="rounded-lg border p-4"
                role="region"
                aria-label={ex.exercise_name}
              >
                <p className="mb-2 font-medium">{ex.exercise_name}</p>
                <div className="space-y-1.5">
                  {ex.sets.map((set) => (
                    <div
                      key={set.set_number}
                      className="flex items-center gap-2 text-sm sm:gap-3"
                    >
                      <span className="w-8 shrink-0 text-muted-foreground sm:w-12">
                        <span className="sm:hidden">S{set.set_number}</span>
                        <span className="hidden sm:inline">Set {set.set_number}</span>
                      </span>
                      <span className="w-14 shrink-0 sm:w-16">
                        {set.reps} reps
                      </span>
                      <span
                        className="min-w-0 flex-1 truncate"
                        title={set.weight > 0 ? `${set.weight} ${set.unit || "lbs"}` : "Bodyweight"}
                      >
                        {set.weight > 0
                          ? `${set.weight} ${set.unit || "lbs"}`
                          : "BW"}
                      </span>
                      <Badge
                        variant={set.completed ? "default" : "secondary"}
                        className="h-5 gap-1 px-1.5"
                      >
                        {set.completed ? (
                          <Check className="h-3 w-3" aria-hidden="true" />
                        ) : (
                          <X className="h-3 w-3" aria-hidden="true" />
                        )}
                        <span className="sr-only">
                          {set.completed ? "Completed" : "Skipped"}
                        </span>
                      </Badge>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}

        {data?.notes && (
          <div className="border-t pt-3">
            <p className="text-xs font-medium text-muted-foreground">Notes</p>
            <p className="mt-1 text-sm">{data.notes}</p>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
