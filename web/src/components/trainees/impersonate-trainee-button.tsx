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
import {
  getAccessToken,
  getRefreshToken,
  setTokens,
  setRoleCookie,
} from "@/lib/token-manager";
import type { ImpersonationStartResponse } from "@/types/trainee-view";
import {
  setTrainerImpersonationState,
} from "@/components/layout/trainer-impersonation-banner";

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
      apiClient.post<ImpersonationStartResponse>(
        API_URLS.trainerImpersonateStart(traineeId),
        {},
      ),
    onSuccess: (data) => {
      // AC-1: Save trainer's current tokens to sessionStorage
      const trainerAccess = getAccessToken();
      const trainerRefresh = getRefreshToken();

      if (!trainerAccess || !trainerRefresh) {
        toast.error("Failed to save trainer session. Please try again.");
        return;
      }

      // AC-4: Save trainee ID and name alongside trainer tokens
      setTrainerImpersonationState({
        trainerAccessToken: trainerAccess,
        trainerRefreshToken: trainerRefresh,
        traineeId: data.trainee.id,
        traineeName:
          `${data.trainee.first_name} ${data.trainee.last_name}`.trim() ||
          data.trainee.email,
      });

      // AC-2: Set trainee JWT tokens
      setTokens(data.access, data.refresh);

      // AC-3: Set role cookie to TRAINEE
      setRoleCookie("TRAINEE");

      toast.success(`Now viewing as ${traineeName}`);

      // AC-5: Hard navigate to /trainee-view to clear React Query cache
      window.location.href = "/trainee-view";
    },
    // AC-6: If API call fails, trainer stays on current page
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
