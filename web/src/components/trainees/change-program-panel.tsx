"use client";

import { useCallback, useState } from "react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { SlideOverPanel } from "@/components/ui/slide-over-panel";
import { usePrograms, useAssignProgram } from "@/hooks/use-programs";
import { getErrorMessage } from "@/lib/error-utils";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import { useLocale } from "@/providers/locale-provider";

interface ChangeProgramPanelProps {
  traineeId: number;
  traineeName: string;
  currentProgramId?: number;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function ChangeProgramPanel({
  traineeId,
  traineeName,
  currentProgramId,
  open,
  onOpenChange,
}: ChangeProgramPanelProps) {
  const { t } = useLocale();
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const { data, isLoading } = usePrograms(1, "");

  const assignMutation = useAssignProgram(selectedId ?? 0);

  const handleAssign = useCallback(() => {
    if (!selectedId) return;

    assignMutation.mutate(
      { trainee_id: traineeId, start_date: new Date().toISOString().split("T")[0] },
      {
        onSuccess: () => {
          toast.success(t("programs.programAssigned"));
          onOpenChange(false);
          setSelectedId(null);
        },
        onError: (err) => toast.error(getErrorMessage(err)),
      },
    );
  }, [selectedId, traineeId, assignMutation, onOpenChange]);

  const programs = data?.results ?? [];

  return (
    <SlideOverPanel
      open={open}
      onOpenChange={onOpenChange}
      title={currentProgramId ? "Change Program" : "Assign Program"}
      description={`Select a program template for ${traineeName}`}
      width="sm"
      footer={
        <>
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
        </>
      }
    >
      <div className="space-y-2">
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
    </SlideOverPanel>
  );
}
