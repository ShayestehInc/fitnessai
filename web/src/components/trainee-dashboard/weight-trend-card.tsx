"use client";

import { Scale, TrendingUp, TrendingDown, Minus } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { useTraineeWeightHistory } from "@/hooks/use-trainee-dashboard";

function CardSkeleton() {
  return (
    <Card>
      <CardHeader className="pb-3">
        <Skeleton className="h-5 w-28" />
      </CardHeader>
      <CardContent className="space-y-3">
        <Skeleton className="h-8 w-24" />
        <Skeleton className="h-4 w-32" />
      </CardContent>
    </Card>
  );
}

export function WeightTrendCard() {
  const { data: checkIns, isLoading, isError, refetch } =
    useTraineeWeightHistory();

  if (isLoading) return <CardSkeleton />;

  if (isError) {
    return (
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Scale className="h-4 w-4" aria-hidden="true" />
            Weight
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

  if (!checkIns?.length) {
    return (
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Scale className="h-4 w-4" aria-hidden="true" />
            Weight
          </CardTitle>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Scale}
            title="No weight data yet"
            description="Log your weight to start tracking trends."
          />
        </CardContent>
      </Card>
    );
  }

  // checkIns sorted by date descending from API
  const latest = checkIns[0];
  const previous = checkIns.length > 1 ? checkIns[1] : null;
  const change = previous
    ? Number((latest.weight_kg - previous.weight_kg).toFixed(1))
    : null;

  const TrendIcon =
    change === null || change === 0
      ? Minus
      : change > 0
        ? TrendingUp
        : TrendingDown;
  const trendColor =
    change === null || change === 0
      ? "text-muted-foreground"
      : change > 0
        ? "text-amber-500"
        : "text-green-500";

  // Convert kg to lbs for display (show both)
  const weightLbs = Number((latest.weight_kg * 2.20462).toFixed(1));

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Scale className="h-4 w-4" aria-hidden="true" />
          Weight
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-baseline gap-2">
          <span className="text-2xl font-bold">
            {Number(latest.weight_kg).toFixed(1)} kg
          </span>
          <span className="text-sm text-muted-foreground">
            ({weightLbs} lbs)
          </span>
        </div>
        <div className="mt-1 flex items-center gap-1.5">
          {change !== null && (
            <>
              <TrendIcon
                className={`h-4 w-4 ${trendColor}`}
                aria-hidden="true"
              />
              <span className={`text-sm font-medium ${trendColor}`}>
                {change > 0 ? "+" : ""}
                {change} kg
              </span>
            </>
          )}
          <span className="text-sm text-muted-foreground">
            {new Date(latest.date).toLocaleDateString(undefined, {
              month: "short",
              day: "numeric",
            })}
          </span>
        </div>
      </CardContent>
    </Card>
  );
}
