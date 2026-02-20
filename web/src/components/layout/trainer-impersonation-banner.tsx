"use client";

import { useCallback, useState } from "react";
import { AlertTriangle, Loader2, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { setTokens, setRoleCookie } from "@/lib/token-manager";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";
import type { TrainerImpersonationState } from "@/types/trainee-view";

const TRAINER_IMPERSONATION_KEY = "fitnessai_trainer_impersonation";

export function getTrainerImpersonationState(): TrainerImpersonationState | null {
  if (typeof window === "undefined") return null;
  const stored = sessionStorage.getItem(TRAINER_IMPERSONATION_KEY);
  if (!stored) return null;
  try {
    return JSON.parse(stored) as TrainerImpersonationState;
  } catch {
    return null;
  }
}

export function setTrainerImpersonationState(
  state: TrainerImpersonationState,
): void {
  sessionStorage.setItem(TRAINER_IMPERSONATION_KEY, JSON.stringify(state));
}

export function clearTrainerImpersonationState(): void {
  sessionStorage.removeItem(TRAINER_IMPERSONATION_KEY);
}

export function TrainerImpersonationBanner() {
  const [state, setState] = useState<TrainerImpersonationState | null>(() =>
    typeof window !== "undefined" ? getTrainerImpersonationState() : null,
  );
  const [isEnding, setIsEnding] = useState(false);

  const handleEndImpersonation = useCallback(async () => {
    if (!state || isEnding) return;
    setIsEnding(true);

    // AC-9: Call end-impersonation API
    try {
      await apiClient.post(API_URLS.TRAINER_IMPERSONATE_END);
    } catch (error) {
      // AC-11: If API call fails, still restore tokens and redirect
      const message = getErrorMessage(error);
      toast.warning(`Warning: ${message}`);
    }

    // AC-9: Restore trainer tokens from sessionStorage
    setTokens(state.trainerAccessToken, state.trainerRefreshToken);

    // AC-9: Set role cookie back to TRAINER
    setRoleCookie("TRAINER");

    // AC-9: Clear impersonation state
    clearTrainerImpersonationState();
    setState(null);
    setIsEnding(false);

    // AC-10: Hard-navigate back to trainee detail page
    window.location.href = `/trainees/${state.traineeId}`;
  }, [state, isEnding]);

  if (!state) return null;

  return (
    <div
      className="flex items-center justify-between bg-amber-500 px-4 py-2 text-amber-950 dark:bg-amber-600 dark:text-amber-50"
      role="status"
      aria-live="polite"
    >
      <div className="flex items-center gap-2">
        <AlertTriangle className="h-4 w-4" aria-hidden="true" />
        <span className="text-sm font-medium">
          Viewing as {state.traineeName}
        </span>
        <span className="rounded bg-amber-600/20 px-1.5 py-0.5 text-xs font-semibold uppercase">
          Read-Only
        </span>
        <span className="sr-only">(trainer impersonation mode active)</span>
      </div>
      <Button
        variant="outline"
        size="sm"
        onClick={handleEndImpersonation}
        disabled={isEnding}
        className="border-amber-700 bg-transparent text-amber-950 hover:bg-amber-600 dark:border-amber-300 dark:text-amber-50 dark:hover:bg-amber-700"
      >
        {isEnding ? (
          <>
            <Loader2
              className="mr-1 h-3 w-3 animate-spin"
              aria-hidden="true"
            />
            Ending...
          </>
        ) : (
          <>
            <X className="mr-1 h-3 w-3" aria-hidden="true" />
            End Impersonation
          </>
        )}
      </Button>
    </div>
  );
}
