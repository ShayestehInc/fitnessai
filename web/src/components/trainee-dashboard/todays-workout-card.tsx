"use client";

import { Dumbbell, BedDouble, CalendarOff } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { useTraineeDashboardPrograms } from "@/hooks/use-trainee-dashboard";
import type {
  TraineeViewSchedule,
  TraineeViewScheduleDay,
} from "@/types/trainee-view";

function getTodaysDayNumber(): number {
  // JavaScript: Sunday = 0, Monday = 1 ... Saturday = 6
  // Schedule: day_number 1 = Monday ... 7 = Sunday
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
  // Use the first week as the current template
  const week = schedule.weeks[0];
  if (!week?.days?.length) return null;
  const todayNum = getTodaysDayNumber();
  const todayName = DAY_NAMES[todayNum] ?? "";
  // Match by day string (could be "1" or "Monday")
  return (
    week.days.find(
      (d) => d.day === String(todayNum) || d.day === todayName,
    ) ?? null
  );
}

function CardSkeleton() {
  return (
    <Card>
      <CardHeader className="pb-3">
        <Skeleton className="h-5 w-32" />
      </CardHeader>
      <CardContent className="space-y-3">
        <Skeleton className="h-4 w-48" />
        <Skeleton className="h-4 w-40" />
        <Skeleton className="h-4 w-36" />
        <Skeleton className="h-4 w-44" />
      </CardContent>
    </Card>
  );
}

export function TodaysWorkoutCard() {
  const { data: programs, isLoading, isError, refetch } =
    useTraineeDashboardPrograms();

  if (isLoading) return <CardSkeleton />;

  if (isError) {
    return (
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Dumbbell className="h-4 w-4" aria-hidden="true" />
            Today&apos;s Workout
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load workout"
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
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Dumbbell className="h-4 w-4" aria-hidden="true" />
            Today&apos;s Workout
          </CardTitle>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Dumbbell}
            title="No program assigned"
            description="Your trainer hasn't assigned a program yet."
          />
        </CardContent>
      </Card>
    );
  }

  const todaysDay = findTodaysWorkout(activeProgram.schedule);
  const isRestDay = todaysDay?.is_rest_day === true;
  const hasExercises = (todaysDay?.exercises?.length ?? 0) > 0;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Dumbbell className="h-4 w-4" aria-hidden="true" />
          Today&apos;s Workout
        </CardTitle>
        <p className="text-sm text-muted-foreground">{activeProgram.name}</p>
      </CardHeader>
      <CardContent>
        {!todaysDay ? (
          <div className="flex items-center gap-3 rounded-lg bg-muted/50 p-4">
            <CalendarOff
              className="h-8 w-8 text-muted-foreground"
              aria-hidden="true"
            />
            <div>
              <p className="font-medium">No workout scheduled</p>
              <p className="text-sm text-muted-foreground">
                No matching day found in your program for today.
              </p>
            </div>
          </div>
        ) : isRestDay ? (
          <div className="flex items-center gap-3 rounded-lg bg-muted/50 p-4">
            <BedDouble
              className="h-8 w-8 text-muted-foreground"
              aria-hidden="true"
            />
            <div>
              <p className="font-medium">Rest Day</p>
              <p className="text-sm text-muted-foreground">
                Take it easy — recovery is part of the process.
              </p>
            </div>
          </div>
        ) : !hasExercises ? (
          <div className="flex items-center gap-3 rounded-lg bg-muted/50 p-4">
            <Dumbbell
              className="h-8 w-8 text-muted-foreground"
              aria-hidden="true"
            />
            <div>
              <p className="font-medium">No exercises scheduled</p>
              <p className="text-sm text-muted-foreground">
                This day has no exercises assigned yet.
              </p>
            </div>
          </div>
        ) : (
          <div className="space-y-1">
            {todaysDay.name && (
              <p className="mb-2 text-sm font-medium text-muted-foreground">
                {todaysDay.name}
              </p>
            )}
            <p className="mb-2 text-2xl font-bold">
              {todaysDay.exercises.length}{" "}
              <span className="text-sm font-normal text-muted-foreground">
                exercises
              </span>
            </p>
            <ul className="space-y-1.5">
              {todaysDay.exercises.slice(0, 5).map((ex, i) => (
                <li
                  key={`${ex.exercise_id}-${i}`}
                  className="flex items-center justify-between text-sm"
                >
                  <span className="truncate">{ex.exercise_name}</span>
                  <span className="ml-2 shrink-0 text-muted-foreground">
                    {ex.sets} x {ex.reps}
                  </span>
                </li>
              ))}
              {todaysDay.exercises.length > 5 && (
                <li className="text-sm text-muted-foreground">
                  +{todaysDay.exercises.length - 5} more
                </li>
              )}
            </ul>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
