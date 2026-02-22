"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { useRouter } from "next/navigation";
import { Timer, Dumbbell } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { PageHeader } from "@/components/shared/page-header";
import {
  useTraineeDashboardPrograms,
  useSaveWorkout,
} from "@/hooks/use-trainee-dashboard";
import { ExerciseLogCard, type SetEntry } from "./exercise-log-card";
import { WorkoutFinishDialog } from "./workout-finish-dialog";
import type {
  TraineeViewSchedule,
  TraineeViewScheduleDay,
  TraineeViewScheduleExercise,
} from "@/types/trainee-view";

function getTodaysDayNumber(): number {
  const jsDay = new Date().getDay();
  return jsDay === 0 ? 7 : jsDay;
}

const DAY_NAMES: Record<number, string> = {
  1: "Monday",
  2: "Tuesday",
  3: "Wednesday",
  4: "Thursday",
  5: "Friday",
  6: "Saturday",
  7: "Sunday",
};

function findTodaysWorkout(
  schedule: TraineeViewSchedule | null,
): TraineeViewScheduleDay | null {
  if (!schedule?.weeks?.length) return null;
  const week = schedule.weeks[0];
  if (!week?.days?.length) return null;
  const todayNum = getTodaysDayNumber();
  const todayName = DAY_NAMES[todayNum] ?? "";
  return (
    week.days.find(
      (d) => d.day === String(todayNum) || d.day === todayName,
    ) ?? null
  );
}

function formatDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
}

function getTodayString(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

interface ExerciseState {
  exercise_id: number;
  exercise_name: string;
  sets: SetEntry[];
}

function buildInitialSets(exercise: TraineeViewScheduleExercise): SetEntry[] {
  const targetSets =
    typeof exercise.sets === "number" ? exercise.sets : parseInt(String(exercise.sets)) || 3;
  const targetReps =
    typeof exercise.reps === "number"
      ? exercise.reps
      : parseInt(String(exercise.reps)) || 0;
  const targetWeight =
    typeof exercise.weight === "number" ? exercise.weight : 0;

  return Array.from({ length: targetSets }, (_, i) => ({
    set_number: i + 1,
    reps: targetReps,
    weight: targetWeight,
    unit: exercise.unit || "lbs",
    completed: false,
    isExtra: false,
  }));
}

export function ActiveWorkout() {
  const router = useRouter();
  const { data: programs, isLoading, isError, refetch } =
    useTraineeDashboardPrograms();
  const saveMutation = useSaveWorkout();

  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [exerciseStates, setExerciseStates] = useState<ExerciseState[]>([]);
  const [showFinishDialog, setShowFinishDialog] = useState(false);
  const [initialized, setInitialized] = useState(false);
  const hasUnsavedRef = useRef(false);

  // Timer
  useEffect(() => {
    const interval = setInterval(() => {
      setElapsedSeconds((prev) => prev + 1);
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  // Track unsaved state for beforeunload
  useEffect(() => {
    hasUnsavedRef.current = exerciseStates.length > 0;
  }, [exerciseStates]);

  // Prevent accidental navigation
  useEffect(() => {
    function handleBeforeUnload(e: BeforeUnloadEvent) {
      if (hasUnsavedRef.current) {
        e.preventDefault();
      }
    }
    window.addEventListener("beforeunload", handleBeforeUnload);
    return () => window.removeEventListener("beforeunload", handleBeforeUnload);
  }, []);

  // Initialize exercise states from program data
  const activeProgram = programs?.find((p) => p.is_active);
  const todaysDay = activeProgram
    ? findTodaysWorkout(activeProgram.schedule)
    : null;

  useEffect(() => {
    if (initialized || !todaysDay?.exercises?.length) return;
    const states: ExerciseState[] = todaysDay.exercises.map((ex) => ({
      exercise_id: ex.exercise_id,
      exercise_name: ex.exercise_name,
      sets: buildInitialSets(ex),
    }));
    setExerciseStates(states);
    setInitialized(true);
  }, [todaysDay, initialized]);

  const handleSetChange = useCallback(
    (exerciseIndex: number, setIndex: number, field: "reps" | "weight", value: number) => {
      setExerciseStates((prev) =>
        prev.map((ex, ei) => {
          if (ei !== exerciseIndex) return ex;
          return {
            ...ex,
            sets: ex.sets.map((s, si) => {
              if (si !== setIndex) return s;
              return { ...s, [field]: value };
            }),
          };
        }),
      );
    },
    [],
  );

  const handleSetToggle = useCallback(
    (exerciseIndex: number, setIndex: number) => {
      setExerciseStates((prev) =>
        prev.map((ex, ei) => {
          if (ei !== exerciseIndex) return ex;
          return {
            ...ex,
            sets: ex.sets.map((s, si) => {
              if (si !== setIndex) return s;
              return { ...s, completed: !s.completed };
            }),
          };
        }),
      );
    },
    [],
  );

  const handleAddSet = useCallback(
    (exerciseIndex: number) => {
      setExerciseStates((prev) =>
        prev.map((ex, ei) => {
          if (ei !== exerciseIndex) return ex;
          const lastSet = ex.sets[ex.sets.length - 1];
          return {
            ...ex,
            sets: [
              ...ex.sets,
              {
                set_number: ex.sets.length + 1,
                reps: lastSet?.reps ?? 0,
                weight: lastSet?.weight ?? 0,
                unit: lastSet?.unit ?? "lbs",
                completed: false,
                isExtra: true,
              },
            ],
          };
        }),
      );
    },
    [],
  );

  const handleRemoveSet = useCallback(
    (exerciseIndex: number, setIndex: number) => {
      setExerciseStates((prev) =>
        prev.map((ex, ei) => {
          if (ei !== exerciseIndex) return ex;
          const filtered = ex.sets.filter((_, si) => si !== setIndex);
          return {
            ...ex,
            sets: filtered.map((s, i) => ({
              ...s,
              set_number: i + 1,
            })),
          };
        }),
      );
    },
    [],
  );

  const handleFinish = useCallback(() => {
    const workoutName = todaysDay?.name || "Workout";
    const duration = formatDuration(elapsedSeconds);

    saveMutation.mutate(
      {
        date: getTodayString(),
        workout_data: {
          workout_name: workoutName,
          duration,
          exercises: exerciseStates.map((ex) => ({
            exercise_id: ex.exercise_id,
            exercise_name: ex.exercise_name,
            sets: ex.sets.map((s) => ({
              set_number: s.set_number,
              reps: s.reps,
              weight: s.weight,
              unit: s.unit,
              completed: s.completed,
            })),
          })),
        },
      },
      {
        onSuccess: () => {
          hasUnsavedRef.current = false;
          toast.success("Workout saved!");
          router.push("/trainee/dashboard");
        },
        onError: () => {
          toast.error("Failed to save workout. Please try again.");
        },
      },
    );
  }, [exerciseStates, elapsedSeconds, todaysDay, saveMutation, router]);

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-8 w-48" />
        <div className="space-y-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-48 w-full" />
          ))}
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <ErrorState
        message="Failed to load workout data"
        onRetry={() => refetch()}
      />
    );
  }

  if (!activeProgram) {
    return (
      <EmptyState
        icon={Dumbbell}
        title="No program assigned"
        description="Your trainer hasn't assigned a program yet. Ask your trainer to set up your training plan."
      />
    );
  }

  if (
    !todaysDay ||
    todaysDay.is_rest_day === true ||
    !todaysDay.exercises?.length
  ) {
    return (
      <EmptyState
        icon={Dumbbell}
        title="No exercises scheduled"
        description="There are no exercises scheduled for today. Check your program for upcoming workouts."
      />
    );
  }

  const workoutName = todaysDay.name || "Workout";

  return (
    <div className="space-y-6">
      <PageHeader
        title={workoutName}
        description={activeProgram.name}
        actions={
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5 rounded-md bg-muted px-3 py-1.5">
              <Timer className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
              <span
                className="font-mono text-sm font-medium tabular-nums"
                aria-label={`Elapsed time: ${formatDuration(elapsedSeconds)}`}
              >
                {formatDuration(elapsedSeconds)}
              </span>
            </div>
            <Button onClick={() => setShowFinishDialog(true)}>
              Finish Workout
            </Button>
          </div>
        }
      />

      <div className="grid gap-4 md:grid-cols-2">
        {exerciseStates.map((ex, i) => {
          const targetExercise = todaysDay.exercises[i];
          return (
            <ExerciseLogCard
              key={ex.exercise_id}
              exerciseIndex={i}
              exerciseName={ex.exercise_name}
              targetSets={targetExercise?.sets ?? ex.sets.length}
              targetReps={targetExercise?.reps ?? 0}
              targetWeight={targetExercise?.weight ?? 0}
              unit={ex.sets[0]?.unit ?? "lbs"}
              sets={ex.sets}
              onSetChange={handleSetChange}
              onSetToggle={handleSetToggle}
              onAddSet={handleAddSet}
              onRemoveSet={handleRemoveSet}
            />
          );
        })}
      </div>

      <WorkoutFinishDialog
        open={showFinishDialog}
        onOpenChange={setShowFinishDialog}
        workoutName={workoutName}
        duration={formatDuration(elapsedSeconds)}
        exercises={exerciseStates}
        onConfirm={handleFinish}
        isPending={saveMutation.isPending}
      />
    </div>
  );
}
