"use client";

import { useRouter } from "next/navigation";
import { TrendingDown, TrendingUp } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { DataTable, type Column } from "@/components/shared/data-table";
import { useProgressAnalytics } from "@/hooks/use-analytics";
import type { TraineeProgressEntry } from "@/types/analytics";

const GOAL_LABELS: Record<string, string> = {
  weight_loss: "Weight Loss",
  muscle_gain: "Muscle Gain",
  maintenance: "Maintenance",
  body_recomposition: "Body Recomposition",
};

function formatGoal(goal: string | null): string {
  if (!goal) return "Not set";
  return GOAL_LABELS[goal] ?? goal;
}

function getWeightChangeColor(
  weightChange: number | null,
  goal: string | null,
): string {
  if (weightChange === null || weightChange === 0) return "";
  if (goal === "weight_loss") {
    return weightChange < 0
      ? "text-green-600 dark:text-green-400"
      : "text-red-600 dark:text-red-400";
  }
  if (goal === "muscle_gain") {
    return weightChange > 0
      ? "text-green-600 dark:text-green-400"
      : "text-red-600 dark:text-red-400";
  }
  return "";
}

function WeightChangeCell({
  weightChange,
  goal,
}: {
  weightChange: number | null;
  goal: string | null;
}) {
  if (weightChange === null) return <span>—</span>;

  const color = getWeightChangeColor(weightChange, goal);
  const sign = weightChange > 0 ? "+" : "";
  const Icon = weightChange > 0 ? TrendingUp : weightChange < 0 ? TrendingDown : null;

  return (
    <span className={`inline-flex items-center gap-1 ${color}`}>
      {Icon && <Icon className="h-3.5 w-3.5" aria-hidden="true" />}
      {sign}
      {weightChange.toFixed(1)} kg
    </span>
  );
}

const columns: Column<TraineeProgressEntry>[] = [
  {
    key: "name",
    header: "Name",
    cell: (row) => (
      <span className="font-medium" title={row.trainee_name}>
        {row.trainee_name}
      </span>
    ),
  },
  {
    key: "current_weight",
    header: "Current Weight",
    cell: (row) => (
      <span>
        {row.current_weight !== null ? `${row.current_weight.toFixed(1)} kg` : "—"}
      </span>
    ),
  },
  {
    key: "weight_change",
    header: "Weight Change",
    cell: (row) => (
      <WeightChangeCell weightChange={row.weight_change} goal={row.goal} />
    ),
  },
  {
    key: "goal",
    header: "Goal",
    cell: (row) => <span>{formatGoal(row.goal)}</span>,
  },
];

function ProgressSkeleton() {
  return (
    <Card>
      <CardHeader>
        <Skeleton className="h-5 w-32" />
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          <Skeleton className="h-10 w-full" />
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-12 w-full" />
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

export function ProgressSection() {
  const router = useRouter();
  const { data, isLoading, isError, refetch } = useProgressAnalytics();

  return (
    <section aria-labelledby="progress-heading">
      <h2 id="progress-heading" className="mb-4 text-lg font-semibold">
        Progress
      </h2>

      {isLoading && <ProgressSkeleton />}

      {isError && (
        <ErrorState
          message="Failed to load progress data"
          onRetry={() => refetch()}
        />
      )}

      {data && data.trainee_progress.length === 0 && (
        <EmptyState
          icon={TrendingUp}
          title="No progress data"
          description="Trainees will appear here once they start tracking"
        />
      )}

      {data && data.trainee_progress.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Trainee Progress</CardTitle>
          </CardHeader>
          <CardContent>
            <DataTable
              columns={columns}
              data={data.trainee_progress}
              keyExtractor={(row) => row.trainee_id}
              onRowClick={(row) => router.push(`/trainees/${row.trainee_id}`)}
            />
          </CardContent>
        </Card>
      )}
    </section>
  );
}
