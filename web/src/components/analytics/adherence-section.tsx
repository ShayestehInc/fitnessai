"use client";

import { useState } from "react";
import { UtensilsCrossed, Dumbbell, Target, BarChart3 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { useAdherenceAnalytics } from "@/hooks/use-analytics";
import { PeriodSelector } from "./period-selector";
import { AdherenceBarChart } from "./adherence-chart";

function getIndicatorColor(rate: number): string {
  if (rate >= 80) return "text-green-600 dark:text-green-400";
  if (rate >= 50) return "text-amber-600 dark:text-amber-400";
  return "text-red-600 dark:text-red-400";
}

interface StatDisplayProps {
  title: string;
  value: number;
  icon: React.ElementType;
}

function StatDisplay({ title, value, icon: Icon }: StatDisplayProps) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
      </CardHeader>
      <CardContent>
        <div className={`text-2xl font-bold ${getIndicatorColor(value)}`}>
          {value.toFixed(1)}%
        </div>
      </CardContent>
    </Card>
  );
}

function AdherenceSkeleton() {
  return (
    <div className="space-y-6">
      <div className="grid gap-4 sm:grid-cols-3">
        {Array.from({ length: 3 }).map((_, i) => (
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
          <Skeleton className="h-[200px] w-full" />
        </CardContent>
      </Card>
    </div>
  );
}

export function AdherenceSection() {
  const [days, setDays] = useState(30);
  const { data, isLoading, isError, refetch } = useAdherenceAnalytics(days);

  return (
    <section aria-labelledby="adherence-heading">
      <div className="mb-4 flex items-center justify-between">
        <h2 id="adherence-heading" className="text-lg font-semibold">
          Adherence
        </h2>
        <PeriodSelector value={days} onChange={setDays} />
      </div>

      {isLoading && <AdherenceSkeleton />}

      {isError && (
        <ErrorState
          message="Failed to load adherence data"
          onRetry={() => refetch()}
        />
      )}

      {data && data.trainee_adherence.length === 0 && (
        <EmptyState
          icon={BarChart3}
          title="No active trainees"
          description="Invite trainees to see analytics"
        />
      )}

      {data && data.trainee_adherence.length > 0 && (
        <div className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-3">
            <StatDisplay
              title="Food Logged"
              value={data.food_logged_rate}
              icon={UtensilsCrossed}
            />
            <StatDisplay
              title="Workouts Logged"
              value={data.workout_logged_rate}
              icon={Dumbbell}
            />
            <StatDisplay
              title="Protein Goal Hit"
              value={data.protein_goal_rate}
              icon={Target}
            />
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">
                Trainee Adherence ({days}-day)
              </CardTitle>
            </CardHeader>
            <CardContent>
              <AdherenceBarChart data={data.trainee_adherence} />
            </CardContent>
          </Card>
        </div>
      )}
    </section>
  );
}
