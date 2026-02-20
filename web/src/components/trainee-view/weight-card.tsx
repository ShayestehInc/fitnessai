"use client";

import { Scale, TrendingDown, TrendingUp, Minus } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { useWeightCheckIns } from "@/hooks/use-trainee-view";
import type { TraineeWeightCheckIn } from "@/types/trainee-view";

function kgToLbs(kg: number): number {
  return kg * 2.20462;
}

function getTrendIcon(checkIns: TraineeWeightCheckIn[]) {
  if (checkIns.length < 2) {
    return <Minus className="h-4 w-4 text-muted-foreground" aria-hidden="true" />;
  }
  const latest = checkIns[0].weight_kg;
  const previous = checkIns[1].weight_kg;
  const diff = latest - previous;

  if (Math.abs(diff) < 0.1) {
    return <Minus className="h-4 w-4 text-muted-foreground" aria-hidden="true" />;
  }
  if (diff > 0) {
    return <TrendingUp className="h-4 w-4 text-orange-500" aria-hidden="true" />;
  }
  return <TrendingDown className="h-4 w-4 text-green-500" aria-hidden="true" />;
}

export function WeightCard() {
  const { data: checkIns, isLoading, isError, refetch } = useWeightCheckIns();

  if (isLoading) {
    return <WeightCardSkeleton />;
  }

  if (isError) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Scale className="h-4 w-4" aria-hidden="true" />
            Recent Weight
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load weight data"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  // Take last 5, sorted by date descending (API returns newest first)
  const recent = checkIns?.slice(0, 5) ?? [];

  if (recent.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Scale className="h-4 w-4" aria-hidden="true" />
            Recent Weight
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center py-6 text-center">
            <Scale
              className="mb-2 h-8 w-8 text-muted-foreground"
              aria-hidden="true"
            />
            <p className="text-sm text-muted-foreground">No weight data</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <Scale className="h-4 w-4" aria-hidden="true" />
          Recent Weight
          {getTrendIcon(recent)}
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          {recent.map((checkIn) => (
            <div
              key={checkIn.id}
              className="flex items-center justify-between text-sm"
            >
              <span className="text-muted-foreground">
                {new Date(checkIn.date).toLocaleDateString(undefined, {
                  month: "short",
                  day: "numeric",
                })}
              </span>
              <span className="font-medium">
                {checkIn.weight_kg.toFixed(1)} kg
                <span className="ml-1 text-xs text-muted-foreground">
                  ({kgToLbs(checkIn.weight_kg).toFixed(1)} lbs)
                </span>
              </span>
            </div>
          ))}
        </div>

        {recent.length >= 2 && (
          <div className="mt-3 border-t pt-3">
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">Change</span>
              <WeightChange
                latest={recent[0].weight_kg}
                earliest={recent[recent.length - 1].weight_kg}
              />
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function WeightChange({
  latest,
  earliest,
}: {
  latest: number;
  earliest: number;
}) {
  const diff = latest - earliest;
  const sign = diff >= 0 ? "+" : "";
  const color =
    Math.abs(diff) < 0.1
      ? "text-muted-foreground"
      : diff > 0
        ? "text-orange-500"
        : "text-green-500";

  return (
    <span className={`font-medium ${color}`}>
      {sign}
      {diff.toFixed(1)} kg
    </span>
  );
}

function WeightCardSkeleton() {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <Scale className="h-4 w-4" aria-hidden="true" />
          Recent Weight
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-2">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="flex items-center justify-between">
            <Skeleton className="h-4 w-16" />
            <Skeleton className="h-4 w-24" />
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
