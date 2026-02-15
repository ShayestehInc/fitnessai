"use client";

import { use } from "react";
import Link from "next/link";
import { ArrowLeft, User } from "lucide-react";
import { useTrainee } from "@/hooks/use-trainees";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ErrorState } from "@/components/shared/error-state";
import { TraineeDetailSkeleton } from "@/components/trainees/trainee-detail-skeleton";
import { TraineeOverviewTab } from "@/components/trainees/trainee-overview-tab";
import { TraineeActivityTab } from "@/components/trainees/trainee-activity-tab";
import { TraineeProgressTab } from "@/components/trainees/trainee-progress-tab";

export default function TraineeDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const traineeId = parseInt(id, 10);
  const isValidId = !isNaN(traineeId) && traineeId > 0;
  const { data: trainee, isLoading, isError, refetch } = useTrainee(
    isValidId ? traineeId : 0,
  );

  if (!isValidId || isError || (!isLoading && !trainee)) {
    return (
      <div className="space-y-6">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/trainees">
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back to Trainees
          </Link>
        </Button>
        <ErrorState
          message={!isValidId ? "Invalid trainee ID" : "Trainee not found or failed to load"}
          onRetry={isValidId ? () => refetch() : undefined}
        />
      </div>
    );
  }

  if (isLoading || !trainee) {
    return <TraineeDetailSkeleton />;
  }

  const displayName =
    `${trainee.first_name} ${trainee.last_name}`.trim() || trainee.email;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <Button variant="ghost" size="sm" className="mb-2" asChild>
            <Link href="/trainees">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back to Trainees
            </Link>
          </Button>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-muted">
              <User className="h-5 w-5 text-muted-foreground" />
            </div>
            <div className="min-w-0">
              <h1 className="truncate text-2xl font-bold tracking-tight" title={displayName}>
                {displayName}
              </h1>
              <p className="truncate text-sm text-muted-foreground">{trainee.email}</p>
            </div>
            <Badge variant={trainee.is_active ? "default" : "secondary"} className="shrink-0">
              {trainee.is_active ? "Active" : "Inactive"}
            </Badge>
          </div>
        </div>
      </div>

      <Tabs defaultValue="overview">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="activity">Activity</TabsTrigger>
          <TabsTrigger value="progress">Progress</TabsTrigger>
        </TabsList>
        <TabsContent value="overview" className="mt-4">
          <TraineeOverviewTab trainee={trainee} />
        </TabsContent>
        <TabsContent value="activity" className="mt-4">
          <TraineeActivityTab traineeId={trainee.id} />
        </TabsContent>
        <TabsContent value="progress" className="mt-4">
          <TraineeProgressTab traineeId={trainee.id} />
        </TabsContent>
      </Tabs>
    </div>
  );
}
