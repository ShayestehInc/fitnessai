"use client";

import { useCallback, useState } from "react";
import { Loader2, Eye } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useMutation } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import { getErrorMessage } from "@/lib/error-utils";

interface ImpersonateTraineeButtonProps {
  traineeId: number;
  traineeName: string;
}

export function ImpersonateTraineeButton({
  traineeId,
  traineeName,
}: ImpersonateTraineeButtonProps) {
  const [confirmOpen, setConfirmOpen] = useState(false);

  const impersonateMutation = useMutation({
    mutationFn: () =>
      apiClient.post<{ session_token: string }>(
        API_URLS.trainerImpersonateStart(traineeId),
        {},
      ),
    onSuccess: (data) => {
      toast.success(`Now viewing as ${traineeName}`);
      // Store impersonation token and redirect to trainee view
      // In practice, the backend sets up the session
      window.location.href = "/dashboard";
    },
    onError: (err) => toast.error(getErrorMessage(err)),
  });

  const handleConfirm = useCallback(() => {
    impersonateMutation.mutate();
  }, [impersonateMutation]);

  return (
    <>
      <Button variant="outline" size="sm" onClick={() => setConfirmOpen(true)}>
        <Eye className="mr-2 h-4 w-4" />
        View as Trainee
      </Button>

      <Dialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Impersonate Trainee</DialogTitle>
            <DialogDescription>
              You will see the app as <strong>{traineeName}</strong> sees it.
              All actions will be logged for audit purposes. You can end the
              session at any time from the banner at the top of the page.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              disabled={impersonateMutation.isPending}
            >
              {impersonateMutation.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
              )}
              Start Impersonation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
