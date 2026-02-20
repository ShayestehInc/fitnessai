"use client";

import { useMemo } from "react";
import { Apple, UtensilsCrossed } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { useNutritionSummary } from "@/hooks/use-trainee-view";

function formatToday(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

interface MacroBarProps {
  label: string;
  consumed: number;
  goal: number;
  unit?: string;
}

function MacroBar({ label, consumed, goal, unit = "g" }: MacroBarProps) {
  const percentage = goal > 0 ? Math.min((consumed / goal) * 100, 100) : 0;
  const isOver = consumed > goal;

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between text-sm">
        <span className="font-medium">{label}</span>
        <span className={isOver ? "text-destructive" : "text-muted-foreground"}>
          {Math.round(consumed)} / {Math.round(goal)} {unit}
        </span>
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-muted">
        <div
          className={`h-full rounded-full transition-all ${
            isOver
              ? "bg-destructive"
              : percentage >= 90
                ? "bg-green-500"
                : "bg-primary"
          }`}
          style={{ width: `${percentage}%` }}
          role="progressbar"
          aria-valuenow={Math.round(consumed)}
          aria-valuemin={0}
          aria-valuemax={Math.round(goal)}
          aria-label={`${label}: ${Math.round(consumed)} of ${Math.round(goal)} ${unit}`}
        />
      </div>
    </div>
  );
}

export function NutritionCard() {
  const today = useMemo(() => formatToday(), []);
  const { data: summary, isLoading, isError, refetch } =
    useNutritionSummary(today);

  if (isLoading) {
    return <NutritionCardSkeleton />;
  }

  if (isError) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Apple className="h-4 w-4" aria-hidden="true" />
            Today&apos;s Nutrition
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load nutrition data"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  if (!summary) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Apple className="h-4 w-4" aria-hidden="true" />
            Today&apos;s Nutrition
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center py-6 text-center">
            <UtensilsCrossed
              className="mb-2 h-8 w-8 text-muted-foreground"
              aria-hidden="true"
            />
            <p className="text-sm text-muted-foreground">
              No data logged today
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <Apple className="h-4 w-4" aria-hidden="true" />
          Today&apos;s Nutrition
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <MacroBar
          label="Calories"
          consumed={summary.consumed.calories}
          goal={summary.goals.calories}
          unit="kcal"
        />
        <MacroBar
          label="Protein"
          consumed={summary.consumed.protein}
          goal={summary.goals.protein}
        />
        <MacroBar
          label="Carbs"
          consumed={summary.consumed.carbs}
          goal={summary.goals.carbs}
        />
        <MacroBar
          label="Fat"
          consumed={summary.consumed.fat}
          goal={summary.goals.fat}
        />

        {summary.meals.length > 0 && (
          <div className="border-t pt-3">
            <p className="mb-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">
              Meals Logged ({summary.meals.length})
            </p>
            <ul className="space-y-1">
              {summary.meals.map((meal, idx) => (
                <li
                  key={`${meal.name}-${idx}`}
                  className="flex items-center justify-between text-sm"
                >
                  <span className="truncate">{meal.name}</span>
                  <span className="shrink-0 text-muted-foreground">
                    {Math.round(meal.calories)} kcal
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function NutritionCardSkeleton() {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <Apple className="h-4 w-4" aria-hidden="true" />
          Today&apos;s Nutrition
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="space-y-1">
            <div className="flex items-center justify-between">
              <Skeleton className="h-4 w-16" />
              <Skeleton className="h-3 w-20" />
            </div>
            <Skeleton className="h-2 w-full rounded-full" />
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
