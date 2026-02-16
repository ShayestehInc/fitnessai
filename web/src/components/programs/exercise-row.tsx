"use client";

import { ArrowUp, ArrowDown, Trash2 } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import type { ScheduleExercise } from "@/types/program";

interface ExerciseRowProps {
  exercise: ScheduleExercise;
  index: number;
  totalExercises: number;
  onUpdate: (updated: ScheduleExercise) => void;
  onRemove: () => void;
  onMoveUp: () => void;
  onMoveDown: () => void;
}

export function ExerciseRow({
  exercise,
  index,
  totalExercises,
  onUpdate,
  onRemove,
  onMoveUp,
  onMoveDown,
}: ExerciseRowProps) {
  const updateField = <K extends keyof ScheduleExercise>(
    field: K,
    value: ScheduleExercise[K],
  ) => {
    onUpdate({ ...exercise, [field]: value });
  };

  return (
    <div className="flex items-center gap-2 rounded-md border bg-card p-2">
      <span
        className="w-6 shrink-0 text-center text-xs font-medium text-muted-foreground"
        aria-label={`Exercise ${index + 1}`}
      >
        {index + 1}
      </span>

      <div className="min-w-0 flex-1">
        <p
          className="truncate text-sm font-medium"
          title={exercise.exercise_name}
        >
          {exercise.exercise_name}
        </p>
      </div>

      <div className="flex items-center gap-1.5">
        <div className="flex items-center gap-1">
          <label className="sr-only" htmlFor={`sets-${exercise.exercise_id}-${index}`}>
            Sets
          </label>
          <Input
            id={`sets-${exercise.exercise_id}-${index}`}
            type="number"
            min={1}
            max={20}
            value={exercise.sets}
            onChange={(e) =>
              updateField("sets", Math.max(1, parseInt(e.target.value) || 1))
            }
            className="h-8 w-14 text-center text-xs"
            aria-label="Sets"
          />
          <span className="text-xs text-muted-foreground">sets</span>
        </div>

        <span className="text-xs text-muted-foreground" aria-hidden="true">
          x
        </span>

        <div className="flex items-center gap-1">
          <label className="sr-only" htmlFor={`reps-${exercise.exercise_id}-${index}`}>
            Reps
          </label>
          <Input
            id={`reps-${exercise.exercise_id}-${index}`}
            type="number"
            min={1}
            max={100}
            value={typeof exercise.reps === "number" ? exercise.reps : 0}
            onChange={(e) =>
              updateField("reps", Math.max(1, parseInt(e.target.value) || 1))
            }
            className="h-8 w-14 text-center text-xs"
            aria-label="Reps"
          />
          <span className="text-xs text-muted-foreground">reps</span>
        </div>

        <div className="flex items-center gap-1">
          <label className="sr-only" htmlFor={`weight-${exercise.exercise_id}-${index}`}>
            Weight
          </label>
          <Input
            id={`weight-${exercise.exercise_id}-${index}`}
            type="number"
            min={0}
            step={2.5}
            value={exercise.weight}
            onChange={(e) =>
              updateField("weight", Math.max(0, parseFloat(e.target.value) || 0))
            }
            className="h-8 w-16 text-center text-xs"
            aria-label="Weight"
          />
          <select
            value={exercise.unit}
            onChange={(e) =>
              updateField("unit", e.target.value as "lbs" | "kg")
            }
            className="h-8 rounded-md border bg-background px-1 text-xs"
            aria-label="Weight unit"
          >
            <option value="lbs">lbs</option>
            <option value="kg">kg</option>
          </select>
        </div>

        <div className="flex items-center gap-1">
          <label className="sr-only" htmlFor={`rest-${exercise.exercise_id}-${index}`}>
            Rest seconds
          </label>
          <Input
            id={`rest-${exercise.exercise_id}-${index}`}
            type="number"
            min={0}
            max={600}
            step={15}
            value={exercise.rest_seconds}
            onChange={(e) =>
              updateField(
                "rest_seconds",
                Math.max(0, parseInt(e.target.value) || 0),
              )
            }
            className="h-8 w-14 text-center text-xs"
            aria-label="Rest seconds"
          />
          <span className="text-xs text-muted-foreground">s</span>
        </div>
      </div>

      <div className="flex shrink-0 items-center gap-0.5">
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="h-7 w-7"
          onClick={onMoveUp}
          disabled={index === 0}
          aria-label="Move exercise up"
        >
          <ArrowUp className="h-3.5 w-3.5" aria-hidden="true" />
        </Button>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="h-7 w-7"
          onClick={onMoveDown}
          disabled={index === totalExercises - 1}
          aria-label="Move exercise down"
        >
          <ArrowDown className="h-3.5 w-3.5" aria-hidden="true" />
        </Button>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="h-7 w-7 text-destructive hover:text-destructive"
          onClick={onRemove}
          aria-label={`Remove ${exercise.exercise_name}`}
        >
          <Trash2 className="h-3.5 w-3.5" aria-hidden="true" />
        </Button>
      </div>
    </div>
  );
}
