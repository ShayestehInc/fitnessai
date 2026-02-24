"use client";

import { Loader2, Trophy, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { SetEntry } from "./exercise-log-card";

interface WorkoutFinishDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  workoutName: string;
  duration: string;
  exercises: Array<{
    exercise_name: string;
    sets: SetEntry[];
  }>;
  onConfirm: () => void;
  isPending: boolean;
}

export function WorkoutFinishDialog({
  open,
  onOpenChange,
  workoutName,
  duration,
  exercises,
  onConfirm,
  isPending,
}: WorkoutFinishDialogProps) {
  const totalSets = exercises.reduce((sum, ex) => sum + ex.sets.length, 0);
  const completedSets = exercises.reduce(
    (sum, ex) => sum + ex.sets.filter((s) => s.completed).length,
    0,
  );
  const incompleteSets = totalSets - completedSets;
  const totalVolume = exercises.reduce((sum, ex) => {
    return (
      sum +
      ex.sets
        .filter((s) => s.completed)
        .reduce((setSum, s) => setSum + s.weight * s.reps, 0)
    );
  }, 0);
  // Determine primary unit from the first exercise's sets
  const primaryUnit = exercises[0]?.sets[0]?.unit ?? "lbs";

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        // Prevent closing while save is in progress
        if (isPending) return;
        onOpenChange(v);
      }}
    >
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Trophy className="h-5 w-5 text-primary" aria-hidden="true" />
            Finish Workout
          </DialogTitle>
          <DialogDescription>
            Review your workout summary before saving.
          </DialogDescription>
        </DialogHeader>

        <form
          onSubmit={(e) => {
            e.preventDefault();
            onConfirm();
          }}
        >
          <div className="space-y-4 py-2">
            {incompleteSets > 0 && (
              <div
                className="flex items-center gap-2 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800 dark:border-amber-900 dark:bg-amber-950/50 dark:text-amber-200"
                role="alert"
              >
                <AlertTriangle className="h-4 w-4 shrink-0" aria-hidden="true" />
                <span>
                  {incompleteSets} {incompleteSets === 1 ? "set" : "sets"} not
                  marked as completed. You can still save.
                </span>
              </div>
            )}
            <div
              className="rounded-lg bg-muted/50 p-4 space-y-2"
              aria-label="Workout summary"
              role="region"
            >
              <div className="flex justify-between gap-2 text-sm">
                <span className="shrink-0 text-muted-foreground">Workout</span>
                <span className="min-w-0 truncate text-right font-medium" title={workoutName}>{workoutName}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Duration</span>
                <span className="font-medium">{duration}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Exercises</span>
                <span className="font-medium">{exercises.length}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Sets Completed</span>
                <span className="font-medium">
                  {completedSets} / {totalSets}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Total Volume</span>
                <span className="font-medium">
                  {new Intl.NumberFormat("en-US").format(Math.round(totalVolume))}{" "}
                  {primaryUnit}
                </span>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isPending}
            >
              Back to Workout
            </Button>
            <Button type="submit" disabled={isPending}>
              {isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
              )}
              Save Workout
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
