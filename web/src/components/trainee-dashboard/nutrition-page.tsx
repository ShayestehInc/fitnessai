"use client";

import { useState, useEffect, useCallback } from "react";
import {
  ChevronLeft,
  ChevronRight,
  CircleSlash,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { MacroBar } from "@/components/shared/macro-bar";
import { useTraineeDashboardNutrition } from "@/hooks/use-trainee-dashboard";
import { getTodayString } from "@/lib/schedule-utils";
import { MealLogInput } from "./meal-log-input";
import { MealHistory } from "./meal-history";
import { MacroPresetChips } from "./macro-preset-chips";

function formatDisplayDate(dateStr: string): string {
  const [year, month, day] = dateStr.split("-").map(Number);
  const d = new Date(year, month - 1, day);
  return d.toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function addDays(dateStr: string, days: number): string {
  const [year, month, day] = dateStr.split("-").map(Number);
  const d = new Date(year, month - 1, day);
  d.setDate(d.getDate() + days);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${dd}`;
}

function MacrosSkeleton() {
  return (
    <Card>
      <CardHeader className="pb-3">
        <Skeleton className="h-5 w-36" />
      </CardHeader>
      <CardContent className="space-y-4">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="space-y-1.5">
            <Skeleton className="h-3 w-20" />
            <Skeleton className="h-2 w-full" />
          </div>
        ))}
      </CardContent>
    </Card>
  );
}

function MealHistorySkeleton() {
  return (
    <Card>
      <CardHeader className="pb-3">
        <Skeleton className="h-5 w-20" />
      </CardHeader>
      <CardContent className="space-y-2">
        {[1, 2, 3].map((i) => (
          <div key={i} className="flex items-center justify-between rounded-md border px-3 py-2">
            <div className="space-y-1">
              <Skeleton className="h-4 w-32" />
              <Skeleton className="h-3 w-48" />
            </div>
            <Skeleton className="h-7 w-7 rounded-md" />
          </div>
        ))}
      </CardContent>
    </Card>
  );
}

export function NutritionPage() {
  const [selectedDate, setSelectedDate] = useState(getTodayString);
  const isToday = selectedDate === getTodayString();

  // Update date if tab stays open past midnight
  useEffect(() => {
    const checkDate = () => {
      const currentToday = getTodayString();
      setSelectedDate((prev) => {
        // Only auto-update if user was viewing the old today
        const oldToday = addDays(currentToday, -1);
        if (prev === oldToday) return currentToday;
        return prev;
      });
    };
    const interval = setInterval(checkDate, 60_000);
    return () => clearInterval(interval);
  }, []);

  const { data, isLoading, isError, refetch } =
    useTraineeDashboardNutrition(selectedDate);

  const goToPreviousDay = useCallback(() => {
    setSelectedDate((prev) => addDays(prev, -1));
  }, []);

  const goToNextDay = useCallback(() => {
    setSelectedDate((prev) => {
      const next = addDays(prev, 1);
      return next > getTodayString() ? prev : next;
    });
  }, []);

  const goToToday = useCallback(() => {
    setSelectedDate(getTodayString());
  }, []);

  const goals = data?.goals ?? { calories: 0, protein: 0, carbs: 0, fat: 0 };
  const consumed = data?.consumed ?? {
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
  };
  const meals = data?.meals ?? [];
  const hasGoals =
    goals.calories > 0 ||
    goals.protein > 0 ||
    goals.carbs > 0 ||
    goals.fat > 0;

  return (
    <div className="space-y-6">
      {/* Date Navigation */}
      <nav
        className="flex items-center justify-center gap-3"
        aria-label="Date navigation"
      >
        <Button
          variant="outline"
          size="icon"
          className="h-8 w-8"
          onClick={goToPreviousDay}
          aria-label="Previous day"
        >
          <ChevronLeft className="h-4 w-4" />
        </Button>

        <span className="min-w-[180px] whitespace-nowrap text-center text-sm font-medium">
          {formatDisplayDate(selectedDate)}
        </span>

        <Button
          variant="outline"
          size="icon"
          className="h-8 w-8"
          onClick={goToNextDay}
          disabled={isToday}
          aria-label="Next day"
        >
          <ChevronRight className="h-4 w-4" />
        </Button>

        {!isToday && (
          <Button
            variant="ghost"
            size="sm"
            onClick={goToToday}
            className="ml-2 text-xs"
          >
            Today
          </Button>
        )}
      </nav>

      {/* Macro Tracking */}
      {isLoading ? (
        <MacrosSkeleton />
      ) : isError ? (
        <ErrorState
          message="Failed to load nutrition data"
          onRetry={() => refetch()}
        />
      ) : !hasGoals ? (
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Macro Goals</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-3 rounded-lg bg-muted/50 p-4">
              <CircleSlash
                className="h-8 w-8 text-muted-foreground"
                aria-hidden="true"
              />
              <div>
                <p className="font-medium">No nutrition goals set</p>
                <p className="text-sm text-muted-foreground">
                  Your trainer hasn&apos;t configured your macro targets yet.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Macro Goals</CardTitle>
            <p className="text-sm text-muted-foreground">
              {isToday ? "Today's macros" : formatDisplayDate(selectedDate)}
            </p>
          </CardHeader>
          <CardContent className="space-y-3">
            <MacroBar
              label="Calories"
              consumed={consumed.calories}
              goal={goals.calories}
              color="hsl(var(--chart-1))"
              unit=" kcal"
            />
            <MacroBar
              label="Protein"
              consumed={consumed.protein}
              goal={goals.protein}
              color="hsl(var(--chart-2))"
            />
            <MacroBar
              label="Carbs"
              consumed={consumed.carbs}
              goal={goals.carbs}
              color="hsl(var(--chart-3))"
            />
            <MacroBar
              label="Fat"
              consumed={consumed.fat}
              goal={goals.fat}
              color="hsl(var(--chart-4))"
            />
          </CardContent>
        </Card>
      )}

      {/* Macro Presets */}
      {hasGoals && !isLoading && !isError && (
        <MacroPresetChips currentGoals={goals} />
      )}

      {/* AI Meal Logging */}
      {!isLoading && !isError && (
        <MealLogInput date={selectedDate} />
      )}

      {/* Meal History */}
      {isLoading ? (
        <MealHistorySkeleton />
      ) : !isError ? (
        <MealHistory meals={meals} date={selectedDate} />
      ) : null}
    </div>
  );
}
