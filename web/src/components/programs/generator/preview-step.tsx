"use client";

import type { GeneratedProgramResponse } from "@/types/program";
import { DIFFICULTY_LABELS, GOAL_LABELS } from "@/types/program";
import type { DifficultyLevel, GoalType } from "@/types/program";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Dumbbell, UtensilsCrossed, Calendar, Flame } from "lucide-react";

interface PreviewStepProps {
  data: GeneratedProgramResponse | null;
  isLoading: boolean;
  error: string | null;
}

export function PreviewStep({ data, isLoading, error }: PreviewStepProps) {
  if (isLoading) {
    return <PreviewSkeleton />;
  }

  if (error) {
    return (
      <div className="rounded-lg border border-destructive/50 bg-destructive/5 p-6 text-center">
        <p className="font-medium text-destructive">Generation failed</p>
        <p className="mt-1 text-sm text-muted-foreground">{error}</p>
      </div>
    );
  }

  if (!data) return null;

  const weeks = data.schedule?.weeks ?? [];
  const firstWeek = weeks[0];
  const workoutDays = firstWeek?.days?.filter((d) => !d.is_rest_day) ?? [];
  const restDays = firstWeek?.days?.filter((d) => d.is_rest_day) ?? [];

  const nutrition = data.nutrition_template as {
    training_day?: { calories: number; protein: number; carbs: number; fat: number };
    rest_day?: { calories: number; protein: number; carbs: number; fat: number };
    note?: string;
  } | undefined;

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold">Program Preview</h3>

      {/* Summary */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">{data.name}</CardTitle>
          <p className="text-sm text-muted-foreground">{data.description}</p>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2">
            <Badge variant="secondary">
              <Calendar className="mr-1 h-3 w-3" aria-hidden="true" />
              {data.duration_weeks} weeks
            </Badge>
            <Badge variant="secondary">
              <Dumbbell className="mr-1 h-3 w-3" aria-hidden="true" />
              {workoutDays.length} days / week
            </Badge>
            <Badge variant="outline">
              {DIFFICULTY_LABELS[data.difficulty_level as DifficultyLevel]}
            </Badge>
            <Badge variant="outline">
              {GOAL_LABELS[data.goal_type as GoalType]}
            </Badge>
          </div>
        </CardContent>
      </Card>

      {/* Weekly Schedule */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Weekly Schedule</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {firstWeek?.days?.map((day, i) => (
            <div key={i} className="flex items-start gap-3">
              <span className="w-24 shrink-0 text-sm font-medium text-muted-foreground">
                {day.day}
              </span>
              {day.is_rest_day ? (
                <span className="text-sm text-muted-foreground italic">
                  Rest Day
                </span>
              ) : (
                <div className="space-y-0.5">
                  <span className="text-sm font-medium">{day.name}</span>
                  <p className="text-xs text-muted-foreground">
                    {day.exercises.length} exercises
                    {day.exercises.length > 0 && (
                      <>
                        {" — "}
                        {day.exercises
                          .slice(0, 3)
                          .map((e) => e.exercise_name)
                          .join(", ")}
                        {day.exercises.length > 3 && ` +${day.exercises.length - 3} more`}
                      </>
                    )}
                  </p>
                </div>
              )}
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Nutrition */}
      {nutrition?.training_day && (
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base flex items-center gap-2">
              <UtensilsCrossed className="h-4 w-4" aria-hidden="true" />
              Nutrition Template
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="grid gap-3 sm:grid-cols-2">
              <NutritionDayCard
                label="Training Day"
                data={nutrition.training_day}
              />
              {nutrition.rest_day && (
                <NutritionDayCard
                  label="Rest Day"
                  data={nutrition.rest_day}
                />
              )}
            </div>
            {nutrition.note && (
              <p className="text-xs text-muted-foreground italic">
                {nutrition.note}
              </p>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function NutritionDayCard({
  label,
  data,
}: {
  label: string;
  data: { calories: number; protein: number; carbs: number; fat: number };
}) {
  return (
    <div className="rounded-md border p-3 space-y-1">
      <span className="text-sm font-medium">{label}</span>
      <div className="flex items-center gap-1 text-sm">
        <Flame className="h-3 w-3 text-orange-500" aria-hidden="true" />
        <span>{data.calories} cal</span>
      </div>
      <div className="flex gap-3 text-xs text-muted-foreground">
        <span>P: {data.protein}g</span>
        <span>C: {data.carbs}g</span>
        <span>F: {data.fat}g</span>
      </div>
    </div>
  );
}

function PreviewSkeleton() {
  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold">Generating your program...</h3>
      <Card>
        <CardContent className="space-y-3 p-6">
          <Skeleton className="h-5 w-3/4" />
          <Skeleton className="h-4 w-full" />
          <div className="flex gap-2">
            <Skeleton className="h-6 w-20" />
            <Skeleton className="h-6 w-24" />
            <Skeleton className="h-6 w-20" />
          </div>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="space-y-3 p-6">
          {Array.from({ length: 7 }).map((_, i) => (
            <div key={i} className="flex gap-3">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-4 w-48" />
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
