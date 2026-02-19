"use client";

import { useCallback, useState } from "react";
import { CalendarOff, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import { getErrorMessage } from "@/lib/error-utils";
import type { TraineeProgram } from "@/types/trainer";

interface MarkMissedDayDialogProps {
  traineeId: number;
  programs: TraineeProgram[];
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function MarkMissedDayDialog({
  traineeId,
  programs,
  open,
  onOpenChange,
}: MarkMissedDayDialogProps) {
  const [selectedProgramId, setSelectedProgramId] = useState<number | null>(null);
  const [date, setDate] = useState(() => new Date().toISOString().split("T")[0]);
  const [action, setAction] = useState<"skip" | "push">("skip");
  const [reason, setReason] = useState("");
  const queryClient = useQueryClient();

  const activePrograms = programs.filter((p) => p.is_active);

  const markMutation = useMutation({
    mutationFn: (data: { date: string; action: "skip" | "push"; reason?: string }) =>
      apiClient.post(
        API_URLS.programMarkMissed(selectedProgramId ?? 0),
        data,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["trainee", traineeId] });
      queryClient.invalidateQueries({ queryKey: ["trainee-activity", traineeId] });
      toast.success("Day marked as missed");
      onOpenChange(false);
      setReason("");
    },
    onError: (err) => toast.error(getErrorMessage(err)),
  });

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      if (!selectedProgramId) {
        toast.error("Select a program first");
        return;
      }
      if (!date) {
        toast.error("Select a date");
        return;
      }
      markMutation.mutate({
        date,
        action,
        reason: reason.trim() || undefined,
      });
    },
    [selectedProgramId, date, reason, markMutation],
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <CalendarOff className="h-5 w-5" />
            Mark Missed Day
          </DialogTitle>
          <DialogDescription>
            Record a day where the trainee missed their workout
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="missed-program">Program</Label>
            {activePrograms.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No active programs
              </p>
            ) : (
              <select
                id="missed-program"
                value={selectedProgramId ?? ""}
                onChange={(e) =>
                  setSelectedProgramId(
                    e.target.value ? Number(e.target.value) : null,
                  )
                }
                className="h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm"
              >
                <option value="">Select program</option>
                {activePrograms.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="missed-date">Date</Label>
            <Input
              id="missed-date"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              max={new Date().toISOString().split("T")[0]}
            />
          </div>

          <div className="space-y-2">
            <Label>Action</Label>
            <div className="space-y-2">
              <label className="flex items-start gap-3 rounded-md border p-3 transition-colors has-[:checked]:border-primary has-[:checked]:bg-primary/5">
                <input
                  type="radio"
                  name="missed-action"
                  value="skip"
                  checked={action === "skip"}
                  onChange={() => setAction("skip")}
                  className="mt-0.5"
                />
                <div>
                  <p className="text-sm font-medium">Skip</p>
                  <p className="text-xs text-muted-foreground">
                    Mark as rest day with no schedule change
                  </p>
                </div>
              </label>
              <label className="flex items-start gap-3 rounded-md border p-3 transition-colors has-[:checked]:border-primary has-[:checked]:bg-primary/5">
                <input
                  type="radio"
                  name="missed-action"
                  value="push"
                  checked={action === "push"}
                  onChange={() => setAction("push")}
                  className="mt-0.5"
                />
                <div>
                  <p className="text-sm font-medium">Push</p>
                  <p className="text-xs text-muted-foreground">
                    Shift all remaining program days forward by one day
                  </p>
                </div>
              </label>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="missed-reason">Reason (optional)</Label>
            <Input
              id="missed-reason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Sick, travel, etc."
              maxLength={200}
            />
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              type="button"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={
                !selectedProgramId ||
                !date ||
                markMutation.isPending ||
                activePrograms.length === 0
              }
            >
              {markMutation.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
              )}
              Mark Missed
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
