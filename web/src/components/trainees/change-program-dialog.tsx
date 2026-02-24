"use client";

import { useCallback, useState } from "react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { usePrograms, useAssignProgram } from "@/hooks/use-programs";
import { getErrorMessage } from "@/lib/error-utils";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

interface ChangeProgramDialogProps {
  traineeId: number;
  traineeName: string;
  currentProgramId?: number;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function ChangeProgramDialog({
  traineeId,
  traineeName,
  currentProgramId,
  open,
  onOpenChange,
}: ChangeProgramDialogProps) {
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const { data, isLoading } = usePrograms(1, "");

  const assignMutation = useAssignProgram(selectedId ?? 0);

  const handleAssign = useCallback(() => {
    if (!selectedId) return;

    assignMutation.mutate(
      { trainee_id: traineeId, start_date: new Date().toISOString().split("T")[0] },
      {
        onSuccess: () => {
          toast.success("Program assigned successfully");
          onOpenChange(false);
          setSelectedId(null);
        },
        onError: (err) => toast.error(getErrorMessage(err)),
      },
    );
  }, [selectedId, traineeId, assignMutation, onOpenChange]);

  const programs = data?.results ?? [];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-md">
        <DialogHeader>
          <DialogTitle>
            {currentProgramId ? "Change Program" : "Assign Program"}
          </DialogTitle>
          <DialogDescription>
            Select a program template for {traineeName}
          </DialogDescription>
        </DialogHeader>

        <div className="max-h-64 space-y-2 overflow-y-auto">
          {isLoading ? (
            <>
              {[1, 2, 3].map((i) => (
                <Skeleton key={i} className="h-14 w-full" />
              ))}
            </>
          ) : programs.length === 0 ? (
            <p className="py-4 text-center text-sm text-muted-foreground">
              No program templates found. Create one first.
            </p>
          ) : (
            programs.map((program) => (
              <button
                key={program.id}
                onClick={() => setSelectedId(program.id)}
                className={cn(
                  "flex w-full items-center justify-between rounded-md border p-3 text-left transition-colors",
                  selectedId === program.id
                    ? "border-primary bg-primary/5"
                    : "hover:bg-accent",
                  currentProgramId === program.id && "opacity-50",
                )}
                disabled={currentProgramId === program.id}
              >
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium">{program.name}</p>
                  <p className="text-xs text-muted-foreground">
                    {program.duration_weeks ?? 0} weeks
                  </p>
                </div>
                {currentProgramId === program.id && (
                  <span className="shrink-0 text-xs text-muted-foreground">
                    Current
                  </span>
                )}
              </button>
            ))
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            onClick={handleAssign}
            disabled={!selectedId || assignMutation.isPending}
          >
            {assignMutation.isPending && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
            )}
            Assign
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
