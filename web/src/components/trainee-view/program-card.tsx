"use client";

import { Dumbbell, Calendar, FileX } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { useTraineePrograms } from "@/hooks/use-trainee-view";
import type { TraineeViewProgram, TraineeViewScheduleDay } from "@/types/trainee-view";

const DAY_NAMES = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
] as const;

function getTodayScheduleDay(
  program: TraineeViewProgram,
): TraineeViewScheduleDay | null {
  if (!program.schedule?.weeks?.length) return null;

  const todayName = DAY_NAMES[new Date().getDay()];

  // Check first week (current week) for today's schedule
  const firstWeek = program.schedule.weeks[0];
  if (!firstWeek?.days) return null;

  return firstWeek.days.find((d) => d.day === todayName) ?? null;
}

export function ProgramCard() {
  const { data: programs, isLoading, isError, refetch } = useTraineePrograms();

  if (isLoading) {
    return <ProgramCardSkeleton />;
  }

  if (isError) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Dumbbell className="h-4 w-4" aria-hidden="true" />
            Active Program
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load program"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  const activeProgram = programs?.find((p) => p.is_active);

  if (!activeProgram) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Dumbbell className="h-4 w-4" aria-hidden="true" />
            Active Program
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center py-6 text-center">
            <FileX
              className="mb-2 h-8 w-8 text-muted-foreground"
              aria-hidden="true"
            />
            <p className="text-sm text-muted-foreground">
              No program assigned
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const todaySchedule = getTodayScheduleDay(activeProgram);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <Dumbbell className="h-4 w-4" aria-hidden="true" />
          Active Program
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="flex items-center justify-between">
          <p className="font-medium">{activeProgram.name}</p>
          <Badge variant="secondary">Active</Badge>
        </div>

        {activeProgram.start_date && (
          <p className="flex items-center gap-1.5 text-sm text-muted-foreground">
            <Calendar className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
            Started {new Date(activeProgram.start_date).toLocaleDateString()}
          </p>
        )}

        <div className="border-t pt-3">
          <p className="mb-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">
            Today&apos;s Exercises
          </p>
          {todaySchedule?.is_rest_day ? (
            <p className="text-sm text-muted-foreground">Rest Day</p>
          ) : todaySchedule?.exercises?.length ? (
            <ul className="space-y-1">
              {todaySchedule.exercises.map((exercise, idx) => (
                <li
                  key={`${exercise.exercise_id}-${idx}`}
                  className="flex items-center justify-between text-sm"
                >
                  <span className="truncate">{exercise.exercise_name}</span>
                  <span className="shrink-0 text-muted-foreground">
                    {exercise.sets} x {exercise.reps}
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted-foreground">
              No exercises scheduled for today
            </p>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

function ProgramCardSkeleton() {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <Dumbbell className="h-4 w-4" aria-hidden="true" />
          Active Program
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="flex items-center justify-between">
          <Skeleton className="h-4 w-40" />
          <Skeleton className="h-5 w-14 rounded-full" />
        </div>
        <Skeleton className="h-3 w-32" />
        <div className="border-t pt-3 space-y-2">
          <Skeleton className="h-3 w-24" />
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-3/4" />
        </div>
      </CardContent>
    </Card>
  );
}
