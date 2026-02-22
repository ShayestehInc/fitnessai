"use client";

import Link from "next/link";
import { Dumbbell, BedDouble, CalendarOff, ArrowRight, Play, CheckCircle2 } from "lucide-react";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import {
  useTraineeDashboardPrograms,
  useTraineeTodayLog,
} from "@/hooks/use-trainee-dashboard";
import { findTodaysWorkout, getTodayString } from "@/lib/schedule-utils";

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
  const todayStr = getTodayString();
  const { data: todayLogData } = useTraineeTodayLog(todayStr);

  // Check if a workout has already been logged today
  const todayLogs = todayLogData ?? [];
  const hasLoggedToday = todayLogs.some((log) => {
    const wd = log.workout_data;
    if (!wd || typeof wd !== "object") return false;
    const exercises = wd.exercises;
    if (Array.isArray(exercises) && exercises.length > 0) return true;
    const sessions = wd.sessions;
    if (Array.isArray(sessions) && sessions.length > 0) return true;
    return false;
  });

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
  const canStartWorkout = todaysDay && !isRestDay && hasExercises;

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
      <CardFooter className="flex items-center gap-3 pt-0">
        {canStartWorkout && hasLoggedToday ? (
          <Button size="sm" variant="outline" asChild>
            <Link href="/trainee/history">
              <CheckCircle2 className="mr-1.5 h-4 w-4" />
              View Today&apos;s Workout
            </Link>
          </Button>
        ) : canStartWorkout ? (
          <Button size="sm" asChild>
            <Link href="/trainee/workout">
              <Play className="mr-1.5 h-4 w-4" />
              Start Workout
            </Link>
          </Button>
        ) : null}
        <Link
          href="/trainee/program"
          className="inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
        >
          View full program
          <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
        </Link>
      </CardFooter>
    </Card>
  );
}
