"use client";

import { use, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, User, Pencil, Trash2, CalendarOff, MessageSquare } from "lucide-react";
import { useTrainee } from "@/hooks/use-trainees";
import { useStartConversation } from "@/hooks/use-messaging";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ErrorState } from "@/components/shared/error-state";
import { PageTransition } from "@/components/shared/page-transition";
import { TraineeDetailSkeleton } from "@/components/trainees/trainee-detail-skeleton";
import { TraineeOverviewTab } from "@/components/trainees/trainee-overview-tab";
import { TraineeActivityTab } from "@/components/trainees/trainee-activity-tab";
import { TraineeProgressTab } from "@/components/trainees/trainee-progress-tab";
import { AssignProgramAction } from "@/components/trainees/assign-program-action";
import { EditGoalsDialog } from "@/components/trainees/edit-goals-dialog";
import { RemoveTraineeDialog } from "@/components/trainees/remove-trainee-dialog";
import { ImpersonateTraineeButton } from "@/components/trainees/impersonate-trainee-button";
import { MarkMissedDayDialog } from "@/components/trainees/mark-missed-day-dialog";
import { LayoutConfigSelector } from "@/components/trainees/layout-config-selector";

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

  const router = useRouter();
  const startConversation = useStartConversation();

  const [editGoalsOpen, setEditGoalsOpen] = useState(false);
  const [removeOpen, setRemoveOpen] = useState(false);
  const [missedDayOpen, setMissedDayOpen] = useState(false);

  const handleMessageTrainee = () => {
    // Send a greeting message to start the conversation and navigate to it
    startConversation.mutate(
      {
        trainee_id: traineeId,
        content: `Hi ${trainee?.first_name || "there"}!`,
      },
      {
        onSuccess: (result) => {
          router.push(`/messages?conversation=${result.conversation_id}`);
        },
      },
    );
  };

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

  const activeProgram = trainee.programs.find((p) => p.is_active);

  return (
    <PageTransition>
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

          {/* Trainee Actions */}
          <div className="flex flex-wrap items-center gap-2">
            <ImpersonateTraineeButton
              traineeId={trainee.id}
              traineeName={displayName}
            />
            <AssignProgramAction
              traineeId={trainee.id}
              traineeName={displayName}
              currentProgramId={activeProgram?.id}
            />
            <Button
              variant="outline"
              size="sm"
              onClick={handleMessageTrainee}
              disabled={startConversation.isPending}
            >
              <MessageSquare className="mr-2 h-4 w-4" />
              {startConversation.isPending ? "Opening..." : "Message"}
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setEditGoalsOpen(true)}
            >
              <Pencil className="mr-2 h-4 w-4" />
              Edit Goals
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setMissedDayOpen(true)}
            >
              <CalendarOff className="mr-2 h-4 w-4" />
              Mark Missed
            </Button>
            <Button
              variant="outline"
              size="sm"
              className="text-destructive hover:text-destructive"
              onClick={() => setRemoveOpen(true)}
            >
              <Trash2 className="mr-2 h-4 w-4" />
              Remove
            </Button>
          </div>
        </div>

        <Tabs defaultValue="overview">
          <TabsList>
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="activity">Activity</TabsTrigger>
            <TabsTrigger value="progress">Progress</TabsTrigger>
            <TabsTrigger value="settings">Settings</TabsTrigger>
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
          <TabsContent value="settings" className="mt-4">
            <LayoutConfigSelector traineeId={trainee.id} />
          </TabsContent>
        </Tabs>

        {/* Dialogs */}
        <EditGoalsDialog
          traineeId={trainee.id}
          traineeName={displayName}
          currentGoals={trainee.nutrition_goal}
          open={editGoalsOpen}
          onOpenChange={setEditGoalsOpen}
        />
        <RemoveTraineeDialog
          traineeId={trainee.id}
          traineeName={displayName}
          open={removeOpen}
          onOpenChange={setRemoveOpen}
        />
        <MarkMissedDayDialog
          traineeId={trainee.id}
          programs={trainee.programs}
          open={missedDayOpen}
          onOpenChange={setMissedDayOpen}
        />
      </div>
    </PageTransition>
  );
}
