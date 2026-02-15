"use client";

import { useTraineeProgress } from "@/hooks/use-progress";
import { ErrorState } from "@/components/shared/error-state";
import { Skeleton } from "@/components/ui/skeleton";
import { WeightChart, VolumeChart, AdherenceChart } from "./progress-charts";

interface TraineeProgressTabProps {
  traineeId: number;
}

function ProgressSkeleton() {
  return (
    <div className="space-y-6">
      {[1, 2, 3].map((i) => (
        <div key={i} className="rounded-lg border p-6">
          <Skeleton className="mb-2 h-5 w-32" />
          <Skeleton className="mb-4 h-4 w-48" />
          <Skeleton className="h-[250px] w-full" />
        </div>
      ))}
    </div>
  );
}

export function TraineeProgressTab({ traineeId }: TraineeProgressTabProps) {
  const { data, isLoading, isError, refetch } = useTraineeProgress(traineeId);

  if (isLoading) {
    return <ProgressSkeleton />;
  }

  if (isError || !data) {
    return (
      <ErrorState
        message="Failed to load progress data"
        onRetry={() => refetch()}
      />
    );
  }

  return (
    <div className="space-y-6">
      <WeightChart data={data.weight_progress} />
      <VolumeChart data={data.volume_progress} />
      <AdherenceChart data={data.adherence_progress} />
    </div>
  );
}
