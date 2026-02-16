"use client";

import { useState } from "react";
import { Loader2, UserPlus } from "lucide-react";
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
import { useTrainees } from "@/hooks/use-trainees";
import { ApiError } from "@/lib/api-client";
import type { ProgramTemplate } from "@/types/program";

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
  const [startDate, setStartDate] = useState(() => {
    const today = new Date();
    return today.toISOString().split("T")[0];
  });

  const { data: traineesData, isLoading: traineesLoading } = useTrainees(1, "");
  const assignMutation = useAssignProgram(program.id);

  const handleAssign = async () => {
    if (!selectedTraineeId || !startDate) return;

    try {
      await assignMutation.mutateAsync({
        trainee_id: selectedTraineeId,
        start_date: startDate,
      });

      const trainee = traineesData?.results.find(
        (t) => t.id === selectedTraineeId,
      );
      const traineeName = trainee
        ? `${trainee.first_name} ${trainee.last_name}`.trim() ||
          trainee.email
        : "trainee";

      toast.success(`Program assigned to ${traineeName}`);
      setOpen(false);
      setSelectedTraineeId("");
    } catch (error) {
      if (error instanceof ApiError) {
        const body = error.body as Record<string, unknown> | null;
        const message =
          body && typeof body === "object"
            ? Object.values(body).flat().join(", ")
            : "Failed to assign program";
        toast.error(message);
      } else {
        toast.error("Failed to assign program");
      }
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Assign Program</DialogTitle>
          <DialogDescription>
            Assign &ldquo;{program.name}&rdquo; to a trainee. A new program will
            be created based on this template.
          </DialogDescription>
        </DialogHeader>

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
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              >
                <option value="">Select a trainee...</option>
                {traineesData?.results.map((trainee) => (
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
            />
          </div>
        </div>

        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => setOpen(false)}
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
      </DialogContent>
    </Dialog>
  );
}
