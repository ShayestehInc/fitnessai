"use client";

import { Plus, Moon, Dumbbell } from "lucide-react";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ExerciseRow } from "./exercise-row";
import { ExercisePickerDialog } from "./exercise-picker-dialog";
import type { ScheduleDay, ScheduleExercise } from "@/types/program";

const MAX_EXERCISES_PER_DAY = 50;

interface DayEditorProps {
  day: ScheduleDay;
  dayIndex: number;
  onUpdate: (updated: ScheduleDay) => void;
}

export function DayEditor({ day, dayIndex, onUpdate }: DayEditorProps) {
  const updateName = (name: string) => {
    onUpdate({ ...day, name });
  };

  const toggleRestDay = () => {
    // Warn if toggling to rest day would remove exercises
    if (!day.is_rest_day && day.exercises.length > 0) {
      const confirmed = window.confirm(
        `Setting ${day.day} as a rest day will remove ${day.exercises.length} exercise${day.exercises.length !== 1 ? "s" : ""}. Continue?`,
      );
      if (!confirmed) return;
    }
    onUpdate({
      ...day,
      is_rest_day: !day.is_rest_day,
      exercises: day.is_rest_day ? day.exercises : [],
      name: !day.is_rest_day ? "Rest" : day.name === "Rest" ? day.day : day.name,
    });
  };

  const addExercise = (exercise: ScheduleExercise) => {
    if (day.exercises.length >= MAX_EXERCISES_PER_DAY) {
      toast.error(`Maximum ${MAX_EXERCISES_PER_DAY} exercises per day`);
      return;
    }
    onUpdate({ ...day, exercises: [...day.exercises, exercise] });
  };

  const updateExercise = (exerciseIndex: number, updated: ScheduleExercise) => {
    const exercises = [...day.exercises];
    exercises[exerciseIndex] = updated;
    onUpdate({ ...day, exercises });
  };

  const removeExercise = (exerciseIndex: number) => {
    const exercises = day.exercises.filter((_, i) => i !== exerciseIndex);
    onUpdate({ ...day, exercises });
  };

  const moveExercise = (fromIndex: number, direction: -1 | 1) => {
    const toIndex = fromIndex + direction;
    if (toIndex < 0 || toIndex >= day.exercises.length) return;

    const exercises = [...day.exercises];
    const temp = exercises[fromIndex];
    exercises[fromIndex] = exercises[toIndex];
    exercises[toIndex] = temp;
    onUpdate({ ...day, exercises });
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-3">
            <CardTitle className="text-sm font-semibold text-muted-foreground">
              {day.day}
            </CardTitle>
            {!day.is_rest_day && (
              <div className="flex items-center gap-1.5">
                <Label
                  htmlFor={`day-name-${dayIndex}`}
                  className="sr-only"
                >
                  Day name
                </Label>
                <Input
                  id={`day-name-${dayIndex}`}
                  value={day.name}
                  onChange={(e) => updateName(e.target.value)}
                  placeholder="Day name (e.g., Push Day)"
                  className="h-8 w-48 text-sm"
                  maxLength={50}
                />
              </div>
            )}
          </div>

          <Button
            type="button"
            variant={day.is_rest_day ? "default" : "outline"}
            size="sm"
            className="h-7 gap-1.5 text-xs"
            onClick={toggleRestDay}
            aria-pressed={day.is_rest_day}
          >
            <Moon className="h-3.5 w-3.5" aria-hidden="true" />
            Rest Day
          </Button>
        </div>
      </CardHeader>

      {!day.is_rest_day && (
        <CardContent className="space-y-2">
          {day.exercises.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-6 text-center">
              <Dumbbell
                className="mb-2 h-6 w-6 text-muted-foreground"
                aria-hidden="true"
              />
              <p className="text-sm text-muted-foreground">
                No exercises added yet. Click below to add one.
              </p>
            </div>
          ) : (
            <>
              <div className="space-y-1.5">
                {day.exercises.map((exercise, idx) => (
                  <ExerciseRow
                    key={`${exercise.exercise_id}-${idx}`}
                    exercise={exercise}
                    index={idx}
                    totalExercises={day.exercises.length}
                    onUpdate={(updated) => updateExercise(idx, updated)}
                    onRemove={() => removeExercise(idx)}
                    onMoveUp={() => moveExercise(idx, -1)}
                    onMoveDown={() => moveExercise(idx, 1)}
                  />
                ))}
              </div>
              <p className="text-xs text-muted-foreground">
                {day.exercises.length} exercise{day.exercises.length !== 1 ? "s" : ""}
              </p>
            </>
          )}

          <ExercisePickerDialog
            onSelect={addExercise}
            trigger={
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="w-full gap-1.5"
              >
                <Plus className="h-3.5 w-3.5" aria-hidden="true" />
                Add Exercise
              </Button>
            }
          />
        </CardContent>
      )}
    </Card>
  );
}
