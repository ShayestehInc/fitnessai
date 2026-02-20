"use client";

import { useState } from "react";
import Link from "next/link";
import { UtensilsCrossed, Dumbbell, Target, Flame, BarChart3 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { StatCard } from "@/components/dashboard/stat-card";
import { useAdherenceAnalytics } from "@/hooks/use-analytics";
import { PeriodSelector } from "./period-selector";
import { AdherenceBarChart } from "./adherence-chart";
import { AdherenceTrendChart } from "./adherence-trend-chart";
import type { AdherencePeriod } from "@/types/analytics";

function getIndicatorColor(rate: number): string {
  if (rate >= 80) return "text-green-600 dark:text-green-400";
  if (rate >= 50) return "text-amber-600 dark:text-amber-400";
  return "text-red-600 dark:text-red-400";
}

function getIndicatorDescription(rate: number): string {
  if (rate >= 80) return "Above target";
  if (rate >= 50) return "Below target";
  return "Needs attention";
}

function AdherenceSkeleton() {
  return (
    <div className="space-y-6" role="status" aria-label="Loading adherence data">
      <span className="sr-only">Loading adherence data...</span>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[0, 1, 2, 3].map((i) => (
          <Card key={i}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-4 w-4" />
            </CardHeader>
            <CardContent>
              <Skeleton className="h-8 w-20" />
            </CardContent>
          </Card>
        ))}
      </div>
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-40" />
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[240px] w-full" />
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-40" />
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[200px] w-full" />
        </CardContent>
      </Card>
    </div>
  );
}

export function AdherenceSection() {
  const [days, setDays] = useState<AdherencePeriod>(30);
  const { data, isLoading, isError, isFetching, refetch } =
    useAdherenceAnalytics(days);

  const hasData = data && data.trainee_adherence.length > 0;
  const isEmpty = data && data.trainee_adherence.length === 0;

  return (
    <section aria-labelledby="adherence-heading">
      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h2 id="adherence-heading" className="text-lg font-semibold">
          Adherence
        </h2>
        <PeriodSelector value={days} onChange={setDays} disabled={isLoading} />
      </div>

      {isLoading ? (
        <AdherenceSkeleton />
      ) : isError ? (
        <ErrorState
          message="Failed to load adherence data"
          onRetry={() => refetch()}
        />
      ) : isEmpty ? (
        <EmptyState
          icon={BarChart3}
          title="No active trainees"
          description="Invite trainees to see their adherence analytics here."
          action={
            <Button asChild>
              <Link href="/invitations">Invite Trainee</Link>
            </Button>
          }
        />
      ) : hasData ? (
        <div
          className={`space-y-6 transition-opacity duration-200 ${isFetching ? "opacity-50" : "opacity-100"}`}
          aria-busy={isFetching}
        >
          {isFetching && (
            <div className="sr-only" role="status" aria-live="polite">
              Refreshing adherence data...
            </div>
          )}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatCard
              title="Food Logged"
              value={`${data.food_logged_rate.toFixed(1)}%`}
              description={getIndicatorDescription(data.food_logged_rate)}
              icon={UtensilsCrossed}
              valueClassName={getIndicatorColor(data.food_logged_rate)}
            />
            <StatCard
              title="Workouts Logged"
              value={`${data.workout_logged_rate.toFixed(1)}%`}
              description={getIndicatorDescription(data.workout_logged_rate)}
              icon={Dumbbell}
              valueClassName={getIndicatorColor(data.workout_logged_rate)}
            />
            <StatCard
              title="Protein Goal Hit"
              value={`${data.protein_goal_rate.toFixed(1)}%`}
              description={getIndicatorDescription(data.protein_goal_rate)}
              icon={Target}
              valueClassName={getIndicatorColor(data.protein_goal_rate)}
            />
            <StatCard
              title="Calorie Goal Hit"
              value={`${data.calorie_goal_rate.toFixed(1)}%`}
              description={getIndicatorDescription(data.calorie_goal_rate)}
              icon={Flame}
              valueClassName={getIndicatorColor(data.calorie_goal_rate)}
            />
          </div>

          <AdherenceTrendChart days={days} />

          <Card>
            <CardHeader>
              <CardTitle className="text-base">
                Trainee Adherence ({days}-day)
                <span className="ml-2 text-sm font-normal text-muted-foreground">
                  {data.trainee_adherence.length} trainee{data.trainee_adherence.length !== 1 ? "s" : ""}
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <AdherenceBarChart data={data.trainee_adherence} />
            </CardContent>
          </Card>
        </div>
      ) : null}
    </section>
  );
}
