"use client";

import { Loader2, Trophy } from "lucide-react";
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
  const totalVolume = exercises.reduce((sum, ex) => {
    return (
      sum +
      ex.sets
        .filter((s) => s.completed)
        .reduce((setSum, s) => setSum + s.weight * s.reps, 0)
    );
  }, 0);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Trophy className="h-5 w-5 text-primary" aria-hidden="true" />
            Finish Workout
          </DialogTitle>
          <DialogDescription>
            Review your workout summary before saving.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-2">
          <div className="rounded-lg bg-muted/50 p-4 space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Workout</span>
              <span className="font-medium">{workoutName}</span>
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
                lbs
              </span>
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={isPending}
          >
            Back to Workout
          </Button>
          <Button onClick={onConfirm} disabled={isPending}>
            {isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Save Workout
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
