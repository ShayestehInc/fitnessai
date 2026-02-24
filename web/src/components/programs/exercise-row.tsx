"use client";

import { useState } from "react";
import { ArrowUp, ArrowDown, Trash2, Dumbbell } from "lucide-react";
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
  const [imgError, setImgError] = useState(false);

  const updateField = <K extends keyof ScheduleExercise>(
    field: K,
    value: ScheduleExercise[K],
  ) => {
    onUpdate({ ...exercise, [field]: value });
  };

  return (
    <div
      className="rounded-md border bg-card p-2"
      role="group"
      aria-label={`Exercise ${index + 1}: ${exercise.exercise_name}`}
    >
      {/* Top row: index, image, name, reorder/delete actions */}
      <div className="flex items-center gap-2">
        <span
          className="w-6 shrink-0 text-center text-xs font-medium text-muted-foreground"
          aria-hidden="true"
        >
          {index + 1}
        </span>

        {exercise.image_url && !imgError ? (
          <img
            src={exercise.image_url}
            alt=""
            className="h-8 w-10 shrink-0 rounded object-cover"
            onError={() => setImgError(true)}
          />
        ) : (
          <div className="flex h-8 w-10 shrink-0 items-center justify-center rounded bg-muted">
            <Dumbbell className="h-4 w-4 text-muted-foreground" />
          </div>
        )}

        <div className="min-w-0 flex-1">
          <p
            className="truncate text-sm font-medium"
            title={exercise.exercise_name}
          >
            {exercise.exercise_name}
          </p>
        </div>

        <div className="flex shrink-0 items-center gap-0.5">
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="h-8 w-8 sm:h-7 sm:w-7"
            onClick={onMoveUp}
            disabled={index === 0}
            aria-label={`Move ${exercise.exercise_name} up`}
          >
            <ArrowUp className="h-3.5 w-3.5" aria-hidden="true" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="h-8 w-8 sm:h-7 sm:w-7"
            onClick={onMoveDown}
            disabled={index === totalExercises - 1}
            aria-label={`Move ${exercise.exercise_name} down`}
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

      {/* Bottom row: parameter inputs -- wraps responsively */}
      <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-2 pl-0 sm:pl-8">
        <div className="flex items-center gap-1">
          <label
            className="text-xs font-medium text-muted-foreground"
            htmlFor={`sets-${exercise.exercise_id}-${index}`}
          >
            Sets
          </label>
          <Input
            id={`sets-${exercise.exercise_id}-${index}`}
            type="number"
            min={1}
            max={20}
            value={exercise.sets}
            onChange={(e) =>
              updateField("sets", Math.min(20, Math.max(1, parseInt(e.target.value) || 1)))
            }
            className="h-8 w-14 text-center text-xs"
          />
        </div>

        <span className="text-xs text-muted-foreground" aria-hidden="true">
          x
        </span>

        <div className="flex items-center gap-1">
          <label
            className="text-xs font-medium text-muted-foreground"
            htmlFor={`reps-${exercise.exercise_id}-${index}`}
          >
            Reps
          </label>
          <Input
            id={`reps-${exercise.exercise_id}-${index}`}
            type={typeof exercise.reps === "string" ? "text" : "number"}
            min={typeof exercise.reps === "string" ? undefined : 1}
            max={typeof exercise.reps === "string" ? undefined : 100}
            value={exercise.reps}
            onChange={(e) => {
              const val = e.target.value;
              const num = parseInt(val);
              if (isNaN(num)) {
                updateField("reps", val.slice(0, 10));
              } else {
                updateField("reps", Math.min(100, Math.max(1, num)));
              }
            }}
            maxLength={10}
            className="h-8 w-16 text-center text-xs"
          />
        </div>

        <div className="flex items-center gap-1">
          <label
            className="text-xs font-medium text-muted-foreground"
            htmlFor={`weight-${exercise.exercise_id}-${index}`}
          >
            Weight
          </label>
          <Input
            id={`weight-${exercise.exercise_id}-${index}`}
            type="number"
            min={0}
            max={9999}
            step={2.5}
            value={exercise.weight}
            onChange={(e) =>
              updateField("weight", Math.min(9999, Math.max(0, parseFloat(e.target.value) || 0)))
            }
            className="h-8 w-16 text-center text-xs"
          />
          <select
            value={exercise.unit}
            onChange={(e) =>
              updateField("unit", e.target.value as "lbs" | "kg")
            }
            className="h-8 rounded-md border border-input bg-background px-1 text-xs focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            aria-label={`Weight unit for ${exercise.exercise_name}`}
          >
            <option value="lbs">lbs</option>
            <option value="kg">kg</option>
          </select>
        </div>

        <div className="flex items-center gap-1">
          <label
            className="text-xs font-medium text-muted-foreground"
            htmlFor={`rest-${exercise.exercise_id}-${index}`}
          >
            Rest
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
                Math.min(600, Math.max(0, parseInt(e.target.value) || 0)),
              )
            }
            className="h-8 w-16 text-center text-xs"
          />
          <span className="text-xs text-muted-foreground">s</span>
        </div>
      </div>
    </div>
  );
}
