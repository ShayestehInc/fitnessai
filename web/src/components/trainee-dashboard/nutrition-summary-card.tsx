"use client";

import { useMemo } from "react";
import { Apple } from "lucide-react";
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

function MacroBar({ label, consumed, goal, color, unit = "g" }: MacroBarProps) {
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
        style={
          { "--progress-color": color } as React.CSSProperties
        }
      />
    </div>
  );
}

export function NutritionSummaryCard() {
  const today = useMemo(() => {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
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
