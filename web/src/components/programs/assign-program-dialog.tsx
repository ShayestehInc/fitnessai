"use client";

import { useState } from "react";
import Link from "next/link";
import { Loader2, UserPlus, Users } from "lucide-react";
import { toast } from "sonner";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useAssignProgram } from "@/hooks/use-programs";
import { useAllTrainees } from "@/hooks/use-trainees";
import { getErrorMessage } from "@/lib/error-utils";
import type { ProgramTemplate } from "@/types/program";

function getLocalDateString(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

interface AssignProgramDialogProps {
  program: ProgramTemplate;
  trigger: React.ReactNode;
}

export function AssignProgramDialog({
  program,
  trigger,
}: AssignProgramDialogProps) {
  const [open, setOpen] = useState(false);
  const [selectedTraineeId, setSelectedTraineeId] = useState<number | "">("");
  const [startDate, setStartDate] = useState(getLocalDateString);

  const {
    data: traineesData,
    isLoading: traineesLoading,
    isError: traineesError,
    refetch: refetchTrainees,
  } = useAllTrainees();
  const assignMutation = useAssignProgram(program.id);

  const hasNoTrainees =
    !traineesLoading && !traineesError && traineesData?.length === 0;

  const handleOpenChange = (nextOpen: boolean) => {
    setOpen(nextOpen);
    if (!nextOpen) {
      setSelectedTraineeId("");
      setStartDate(getLocalDateString());
    }
  };

  const handleAssign = async () => {
    if (!selectedTraineeId || !startDate) return;

    try {
      await assignMutation.mutateAsync({
        trainee_id: selectedTraineeId,
        start_date: startDate,
      });

      const trainee = traineesData?.find((t) => t.id === selectedTraineeId);
      const traineeName = trainee
        ? `${trainee.first_name} ${trainee.last_name}`.trim() || trainee.email
        : "trainee";

      toast.success(`Program assigned to ${traineeName}`);
      setOpen(false);
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="max-h-[90dvh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Assign Program</DialogTitle>
          <DialogDescription>
            Assign &ldquo;{program.name}&rdquo; to a trainee. A new program will
            be created based on this template.
          </DialogDescription>
        </DialogHeader>

        {traineesError ? (
          <div className="py-4">
            <div className="flex flex-col items-center justify-center text-center">
              <Users className="mb-3 h-8 w-8 text-muted-foreground" aria-hidden="true" />
              <p className="mb-2 text-sm text-destructive">Failed to load trainees</p>
              <Button
                variant="outline"
                size="sm"
                onClick={() => refetchTrainees()}
              >
                Try again
              </Button>
            </div>
          </div>
        ) : hasNoTrainees ? (
          <div className="py-4">
            <div className="flex flex-col items-center justify-center text-center">
              <div className="mb-3 rounded-full bg-muted p-3">
                <Users className="h-6 w-6 text-muted-foreground" aria-hidden="true" />
              </div>
              <p className="mb-1 text-sm font-medium">No trainees yet</p>
              <p className="mb-3 text-xs text-muted-foreground">
                Invite a trainee before assigning programs.
              </p>
              <Button size="sm" asChild>
                <Link href="/invitations" onClick={() => setOpen(false)}>
                  Send Invitation
                </Link>
              </Button>
            </div>
          </div>
        ) : (
          <>
            <div className="space-y-4 py-2">
              <div className="space-y-2">
                <Label htmlFor="assign-trainee">Trainee</Label>
                {traineesLoading ? (
                  <Skeleton className="h-10 w-full" />
                ) : (
                  <select
                    id="assign-trainee"
                    value={selectedTraineeId}
                    onChange={(e) =>
                      setSelectedTraineeId(
                        e.target.value ? Number(e.target.value) : "",
                      )
                    }
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50"
                    disabled={assignMutation.isPending}
                  >
                    <option value="">Select a trainee...</option>
                    {traineesData?.map((trainee) => (
                      <option key={trainee.id} value={trainee.id}>
                        {trainee.first_name} {trainee.last_name} ({trainee.email})
                      </option>
                    ))}
                  </select>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="assign-start-date">Start Date</Label>
                <Input
                  id="assign-start-date"
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  disabled={assignMutation.isPending}
                />
              </div>
            </div>

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => handleOpenChange(false)}
                disabled={assignMutation.isPending}
              >
                Cancel
              </Button>
              <Button
                type="button"
                onClick={handleAssign}
                disabled={
                  !selectedTraineeId || !startDate || assignMutation.isPending
                }
              >
                {assignMutation.isPending ? (
                  <>
                    <Loader2
                      className="mr-2 h-4 w-4 animate-spin"
                      aria-hidden="true"
                    />
                    Assigning...
                  </>
                ) : (
                  <>
                    <UserPlus className="mr-2 h-4 w-4" aria-hidden="true" />
                    Assign
                  </>
                )}
              </Button>
            </DialogFooter>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
