"use client";

import { useState, useEffect } from "react";
import { Apple, CircleSlash } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { useTraineeDashboardNutrition } from "@/hooks/use-trainee-dashboard";
import { getTodayString } from "@/lib/schedule-utils";

function CardSkeleton() {
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

interface MacroBarProps {
  label: string;
  consumed: number;
  goal: number;
  color: string;
  unit?: string;
}

function MacroBar({ label, consumed, goal, color, unit = " g" }: MacroBarProps) {
  const percentage = goal > 0 ? Math.min((consumed / goal) * 100, 100) : 0;

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between text-sm">
        <span className="font-medium">{label}</span>
        <span className="text-muted-foreground">
          {Math.round(consumed)} / {Math.round(goal)}
          {unit}
        </span>
      </div>
      <Progress
        value={percentage}
        className="h-2"
        aria-label={`${label}: ${Math.round(consumed)} of ${Math.round(goal)}${unit}`}
        style={
          { "--progress-color": color } as React.CSSProperties
        }
      />
    </div>
  );
}

export function NutritionSummaryCard() {
  const [today, setToday] = useState(getTodayString);

  // Update the date if the user keeps the tab open past midnight
  useEffect(() => {
    const checkDate = () => {
      const current = getTodayString();
      setToday((prev) => (prev !== current ? current : prev));
    };
    const interval = setInterval(checkDate, 60_000); // check every minute
    return () => clearInterval(interval);
  }, []);

  const { data, isLoading, isError, refetch } =
    useTraineeDashboardNutrition(today);

  if (isLoading) return <CardSkeleton />;

  if (isError) {
    return (
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Apple className="h-4 w-4" aria-hidden="true" />
            Nutrition
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load nutrition"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  const goals = data?.goals ?? { calories: 0, protein: 0, carbs: 0, fat: 0 };
  const consumed = data?.consumed ?? {
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
  };

  const hasGoals =
    goals.calories > 0 ||
    goals.protein > 0 ||
    goals.carbs > 0 ||
    goals.fat > 0;

  if (!hasGoals) {
    return (
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Apple className="h-4 w-4" aria-hidden="true" />
            Nutrition
          </CardTitle>
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
    );
  }

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Apple className="h-4 w-4" aria-hidden="true" />
          Nutrition
        </CardTitle>
        <p className="text-sm text-muted-foreground">Today&apos;s macros</p>
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
  );
}
