"use client";

import { useState } from "react";
import { Scale, TrendingUp, TrendingDown, Minus, Plus } from "lucide-react";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { useTraineeWeightHistory } from "@/hooks/use-trainee-dashboard";
import { WeightCheckInDialog } from "./weight-checkin-dialog";

function CardSkeleton() {
  return (
    <Card aria-busy="true">
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
  const [dialogOpen, setDialogOpen] = useState(false);
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
      <>
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
              description="Log your first weight check-in to start tracking."
              action={
                <Button size="sm" onClick={() => setDialogOpen(true)}>
                  <Plus className="mr-1.5 h-4 w-4" aria-hidden="true" />
                  Log Weight
                </Button>
              }
            />
          </CardContent>
        </Card>
        <WeightCheckInDialog open={dialogOpen} onOpenChange={setDialogOpen} />
      </>
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

  // Use neutral colors — we don't know the user's goal (gain vs lose)
  const trendColor =
    change === null || change === 0
      ? "text-muted-foreground"
      : "text-foreground";

  return (
    <>
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
          </div>
          <p className="mt-1 text-xs text-muted-foreground">
            Last weigh-in:{" "}
            {new Date(latest.date).toLocaleDateString(undefined, {
              month: "short",
              day: "numeric",
              year: "numeric",
            })}
          </p>
          {change !== null && previous && (
            <div
              className="mt-1.5 flex items-center gap-1.5"
              aria-label={`Weight ${change > 0 ? "increased" : change < 0 ? "decreased" : "unchanged"} by ${Math.abs(change)} kg since ${new Date(previous.date).toLocaleDateString(undefined, { month: "short", day: "numeric" })}`}
            >
              <TrendIcon
                className={`h-4 w-4 ${trendColor}`}
                aria-hidden="true"
              />
              <span className={`text-sm font-medium ${trendColor}`} aria-hidden="true">
                {change > 0 ? "+" : ""}
                {change} kg
              </span>
              <span className="text-xs text-muted-foreground" aria-hidden="true">
                since{" "}
                {new Date(previous.date).toLocaleDateString(undefined, {
                  month: "short",
                  day: "numeric",
                })}
              </span>
            </div>
          )}
        </CardContent>
        <CardFooter className="pt-0">
          <Button
            size="sm"
            variant="outline"
            onClick={() => setDialogOpen(true)}
          >
            <Plus className="mr-1.5 h-4 w-4" aria-hidden="true" />
            Log Weight
          </Button>
        </CardFooter>
      </Card>
      <WeightCheckInDialog open={dialogOpen} onOpenChange={setDialogOpen} />
    </>
  );
}
