"use client";

import { useCallback, useState } from "react";
import { Loader2, AlertTriangle } from "lucide-react";
import { toast } from "sonner";
import { useRouter } from "next/navigation";
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

interface RemoveTraineeDialogProps {
  traineeId: number;
  traineeName: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function RemoveTraineeDialog({
  traineeId,
  traineeName,
  open,
  onOpenChange,
}: RemoveTraineeDialogProps) {
  const [confirmation, setConfirmation] = useState("");
  const router = useRouter();
  const queryClient = useQueryClient();

  const removeMutation = useMutation({
    mutationFn: () => apiClient.post(API_URLS.traineeRemove(traineeId), {}),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["trainees"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      toast.success(`${traineeName} has been removed`);
      onOpenChange(false);
      router.push("/trainees");
    },
    onError: (err) => toast.error(getErrorMessage(err)),
  });

  const handleRemove = useCallback(() => {
    if (confirmation !== "REMOVE") return;
    removeMutation.mutate();
  }, [confirmation, removeMutation]);

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!v) setConfirmation("");
        onOpenChange(v);
      }}
    >
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-destructive">
            <AlertTriangle className="h-5 w-5" />
            Remove Trainee
          </DialogTitle>
          <DialogDescription>
            This will permanently remove <strong>{traineeName}</strong> from your
            roster. Their account will still exist but they will no longer be
            linked to you. This action cannot be undone.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-2">
          <Label htmlFor="confirm-remove">
            Type <strong>REMOVE</strong> to confirm
          </Label>
          <Input
            id="confirm-remove"
            value={confirmation}
            onChange={(e) => setConfirmation(e.target.value)}
            placeholder="REMOVE"
            autoComplete="off"
          />
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={removeMutation.isPending}
          >
            Cancel
          </Button>
          <Button
            variant="destructive"
            onClick={handleRemove}
            disabled={confirmation !== "REMOVE" || removeMutation.isPending}
          >
            {removeMutation.isPending && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
            )}
            Remove Trainee
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
