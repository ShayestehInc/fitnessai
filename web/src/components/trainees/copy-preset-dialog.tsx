"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { Loader2, Users } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAllTrainees } from "@/hooks/use-trainees";
import { useCopyMacroPreset } from "@/hooks/use-macro-presets";
import { getErrorMessage } from "@/lib/error-utils";
import type { MacroPreset } from "@/types/trainer";

interface CopyPresetDialogProps {
  traineeId: number;
  preset: MacroPreset | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function CopyPresetDialog({
  traineeId,
  preset,
  open,
  onOpenChange,
}: CopyPresetDialogProps) {
  const [targetTraineeId, setTargetTraineeId] = useState("");
  const { data: allTrainees, isLoading: isLoadingTrainees } = useAllTrainees();
  const copyMutation = useCopyMacroPreset(traineeId);

  const otherTrainees = useMemo(
    () => (allTrainees ?? []).filter((t) => t.id !== traineeId),
    [allTrainees, traineeId],
  );

  useEffect(() => {
    if (open) {
      setTargetTraineeId("");
    }
  }, [open]);

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      if (!preset || !targetTraineeId) return;

      const targetId = Number(targetTraineeId);
      const targetTrainee = otherTrainees.find((t) => t.id === targetId);
      const targetName = targetTrainee
        ? `${targetTrainee.first_name} ${targetTrainee.last_name}`.trim() ||
          targetTrainee.email
        : "trainee";

      copyMutation.mutate(
        { presetId: preset.id, targetTraineeId: targetId },
        {
          onSuccess: () => {
            toast.success(`Preset copied to ${targetName}`);
            onOpenChange(false);
          },
          onError: (err) => toast.error(getErrorMessage(err)),
        },
      );
    },
    [preset, targetTraineeId, otherTrainees, copyMutation, onOpenChange],
  );

  const handleOpenChange = useCallback(
    (nextOpen: boolean) => {
      if (!nextOpen && copyMutation.isPending) return;
      onOpenChange(nextOpen);
    },
    [copyMutation.isPending, onOpenChange],
  );

  if (!preset) return null;

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent
        className="sm:max-w-md"
        onPointerDownOutside={(e) => {
          if (copyMutation.isPending) e.preventDefault();
        }}
        onEscapeKeyDown={(e) => {
          if (copyMutation.isPending) e.preventDefault();
        }}
      >
        <DialogHeader>
          <DialogTitle>Copy Preset</DialogTitle>
          <DialogDescription>
            Copy &ldquo;{preset.name}&rdquo; to another trainee
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="copy-target-trainee">Select Trainee</Label>
            {isLoadingTrainees ? (
              <div className="space-y-2">
                <Skeleton className="h-9 w-full rounded-md" />
                <p className="text-xs text-muted-foreground">Loading trainees...</p>
              </div>
            ) : otherTrainees.length === 0 ? (
              <div className="flex flex-col items-center gap-2 py-4 text-center">
                <Users className="h-5 w-5 text-muted-foreground" aria-hidden="true" />
                <p className="text-sm text-muted-foreground">
                  No other trainees to copy to.
                </p>
              </div>
            ) : (
              <select
                id="copy-target-trainee"
                value={targetTraineeId}
                onChange={(e) => setTargetTraineeId(e.target.value)}
                disabled={copyMutation.isPending}
                aria-label="Select target trainee for preset copy"
                className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-1 disabled:cursor-not-allowed disabled:opacity-50"
              >
                <option value="">Choose a trainee...</option>
                {otherTrainees.map((t) => {
                  const label =
                    `${t.first_name} ${t.last_name}`.trim() || t.email;
                  return (
                    <option key={t.id} value={t.id}>
                      {label}
                    </option>
                  );
                })}
              </select>
            )}
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              type="button"
              onClick={() => handleOpenChange(false)}
              disabled={copyMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={
                !targetTraineeId ||
                isLoadingTrainees ||
                otherTrainees.length === 0 ||
                copyMutation.isPending
              }
            >
              {copyMutation.isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              Copy Preset
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
