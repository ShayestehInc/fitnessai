"use client";

import { Target } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { useTraineeWeeklyProgress } from "@/hooks/use-trainee-dashboard";

function CardSkeleton() {
  return (
    <Card>
      <CardHeader className="pb-3">
        <Skeleton className="h-5 w-32" />
      </CardHeader>
      <CardContent className="space-y-3">
        <Skeleton className="h-8 w-20" />
        <Skeleton className="h-3 w-full" />
      </CardContent>
    </Card>
  );
}

export function WeeklyProgressCard() {
  const { data, isLoading, isError, refetch } = useTraineeWeeklyProgress();

  if (isLoading) return <CardSkeleton />;

  if (isError) {
    return (
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Target className="h-4 w-4" aria-hidden="true" />
            Weekly Progress
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load progress"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  const total = data?.total_days ?? 0;
  const completed = data?.completed_days ?? 0;
  const percentage = data?.percentage ?? 0;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Target className="h-4 w-4" aria-hidden="true" />
          Weekly Progress
        </CardTitle>
        <p className="text-sm text-muted-foreground">This week</p>
      </CardHeader>
      <CardContent>
        <div className="mb-3 flex items-baseline gap-2">
          <span className="text-2xl font-bold">{Math.round(percentage)}%</span>
          <span className="text-sm text-muted-foreground">
            {completed} of {total} days
          </span>
        </div>
        <Progress value={percentage} className="h-3" />
      </CardContent>
    </Card>
  );
}
