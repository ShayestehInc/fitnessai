"use client";

import { Plus, Trash2, Check } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

export interface SetEntry {
  set_number: number;
  reps: number;
  weight: number;
  unit: string;
  completed: boolean;
  isExtra: boolean; // true if added by user beyond program target
}

interface ExerciseLogCardProps {
  exerciseIndex: number;
  exerciseName: string;
  targetSets: number;
  targetReps: number | string;
  targetWeight: number;
  unit: string;
  sets: SetEntry[];
  onSetChange: (exerciseIndex: number, setIndex: number, field: "reps" | "weight", value: number) => void;
  onSetToggle: (exerciseIndex: number, setIndex: number) => void;
  onAddSet: (exerciseIndex: number) => void;
  onRemoveSet: (exerciseIndex: number, setIndex: number) => void;
}

export function ExerciseLogCard({
  exerciseIndex,
  exerciseName,
  targetSets,
  targetReps,
  targetWeight,
  unit,
  sets,
  onSetChange,
  onSetToggle,
  onAddSet,
  onRemoveSet,
}: ExerciseLogCardProps) {
  const completedSets = sets.filter((s) => s.completed).length;

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-base">{exerciseName}</CardTitle>
          <span className="text-sm text-muted-foreground">
            {completedSets}/{sets.length} sets
          </span>
        </div>
        <p className="text-xs text-muted-foreground">
          Target: {targetSets} x {targetReps}
          {targetWeight > 0 ? ` @ ${targetWeight} ${unit}` : ""}
        </p>
      </CardHeader>
      <CardContent className="space-y-2">
        {/* Header row */}
        <div
          className="grid grid-cols-[1.75rem_1fr_1fr_2rem_2rem] items-center gap-1.5 text-xs font-medium text-muted-foreground sm:grid-cols-[2.5rem_1fr_1fr_2.5rem_2.5rem] sm:gap-2"
          aria-hidden="true"
        >
          <span>Set</span>
          <span>Reps</span>
          <span>Wt ({unit})</span>
          <span />
          <span />
        </div>

        {sets.map((set, setIndex) => (
          <div
            key={set.set_number}
            className="grid grid-cols-[1.75rem_1fr_1fr_2rem_2rem] items-center gap-1.5 sm:grid-cols-[2.5rem_1fr_1fr_2.5rem_2.5rem] sm:gap-2"
            role="group"
            aria-label={`Set ${set.set_number}`}
          >
            <span className="text-center text-sm font-medium text-muted-foreground">
              {set.set_number}
            </span>
            <Input
              type="number"
              min={0}
              max={999}
              value={set.reps}
              onChange={(e) => {
                const raw = e.target.value;
                onSetChange(
                  exerciseIndex,
                  setIndex,
                  "reps",
                  raw === "" ? 0 : Math.max(0, parseInt(raw) || 0),
                );
              }}
              className="h-9 min-w-0 px-2 text-sm sm:px-3"
              aria-label={`Set ${set.set_number} reps`}
            />
            <Input
              type="number"
              min={0}
              max={9999}
              step="0.5"
              value={set.weight}
              onChange={(e) => {
                const raw = e.target.value;
                onSetChange(
                  exerciseIndex,
                  setIndex,
                  "weight",
                  raw === "" ? 0 : Math.max(0, parseFloat(raw) || 0),
                );
              }}
              className="h-9 min-w-0 px-2 text-sm sm:px-3"
              aria-label={`Set ${set.set_number} weight`}
            />
            <div className="flex items-center justify-center">
              <button
                type="button"
                role="checkbox"
                aria-checked={set.completed}
                aria-label={`Mark set ${set.set_number} as completed`}
                onClick={() => onSetToggle(exerciseIndex, setIndex)}
                className={cn(
                  "flex h-7 w-7 items-center justify-center rounded border transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 sm:h-5 sm:w-5",
                  set.completed
                    ? "border-primary bg-primary text-primary-foreground"
                    : "border-input bg-background hover:border-primary/50",
                )}
              >
                {set.completed && <Check className="h-3 w-3" aria-hidden="true" />}
              </button>
            </div>
            <div className="flex items-center justify-center">
              {set.isExtra ? (
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-8 w-8 text-muted-foreground hover:text-destructive"
                  onClick={() => onRemoveSet(exerciseIndex, setIndex)}
                  aria-label={`Remove set ${set.set_number}`}
                >
                  <Trash2 className="h-3.5 w-3.5" aria-hidden="true" />
                </Button>
              ) : (
                <span className="h-8 w-8" />
              )}
            </div>
          </div>
        ))}

        <Button
          variant="ghost"
          size="sm"
          className="mt-1 w-full text-muted-foreground"
          onClick={() => onAddSet(exerciseIndex)}
          aria-label={`Add set to ${exerciseName}`}
        >
          <Plus className="mr-1.5 h-3.5 w-3.5" aria-hidden="true" />
          Add Set
        </Button>
      </CardContent>
    </Card>
  );
}
