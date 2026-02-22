"use client";

import { Check, X } from "lucide-react";
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
import type { WorkoutExerciseLog } from "@/types/trainee-dashboard";

interface WorkoutDetailDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  workoutId: number;
}

function getExercises(
  workoutData: Record<string, unknown> | undefined,
): WorkoutExerciseLog[] {
  if (!workoutData) return [];
  // Direct exercises array
  const exercises = workoutData.exercises;
  if (Array.isArray(exercises)) return exercises as WorkoutExerciseLog[];
  // Sessions format (from mobile app)
  const sessions = workoutData.sessions;
  if (Array.isArray(sessions) && sessions.length > 0) {
    const first = sessions[0] as Record<string, unknown>;
    if (Array.isArray(first?.exercises)) {
      return first.exercises as WorkoutExerciseLog[];
    }
  }
  return [];
}

function getWorkoutName(workoutData: Record<string, unknown> | undefined): string {
  if (!workoutData) return "Workout";
  if (typeof workoutData.workout_name === "string" && workoutData.workout_name) {
    return workoutData.workout_name;
  }
  const sessions = workoutData.sessions;
  if (Array.isArray(sessions) && sessions.length > 0) {
    const first = sessions[0] as Record<string, unknown>;
    if (typeof first?.workout_name === "string" && first.workout_name) {
      return first.workout_name;
    }
  }
  return "Workout";
}

export function WorkoutDetailDialog({
  open,
  onOpenChange,
  workoutId,
}: WorkoutDetailDialogProps) {
  const { data, isLoading, isError, refetch } =
    useTraineeWorkoutDetail(workoutId);

  const workoutData = data?.workout_data as Record<string, unknown> | undefined;
  const exercises = getExercises(workoutData);
  const workoutName = getWorkoutName(workoutData);
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
      <DialogContent className="max-h-[80vh] overflow-y-auto sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>{workoutName}</DialogTitle>
          <DialogDescription>{dateFormatted}</DialogDescription>
        </DialogHeader>

        {isLoading && (
          <div className="space-y-4 py-4">
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
          <p className="py-8 text-center text-sm text-muted-foreground">
            No exercise data recorded for this workout.
          </p>
        )}

        {data && exercises.length > 0 && (
          <div className="space-y-4 py-2">
            {exercises.map((ex, i) => (
              <div
                key={`${ex.exercise_id}-${i}`}
                className="rounded-lg border p-4"
              >
                <h4 className="mb-2 font-medium">{ex.exercise_name}</h4>
                <div className="space-y-1.5">
                  {ex.sets.map((set) => (
                    <div
                      key={set.set_number}
                      className="flex items-center gap-3 text-sm"
                    >
                      <span className="w-12 text-muted-foreground">
                        Set {set.set_number}
                      </span>
                      <span className="w-16">
                        {set.reps} reps
                      </span>
                      <span className="w-20">
                        {set.weight > 0
                          ? `${set.weight} ${set.unit || "lbs"}`
                          : "BW"}
                      </span>
                      <Badge
                        variant={set.completed ? "default" : "secondary"}
                        className="h-5 gap-1 px-1.5"
                      >
                        {set.completed ? (
                          <Check className="h-3 w-3" />
                        ) : (
                          <X className="h-3 w-3" />
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
