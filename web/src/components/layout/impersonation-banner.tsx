"use client";

import { useCallback, useState } from "react";
import { AlertTriangle, Loader2, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { setTokens } from "@/lib/token-manager";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";

const IMPERSONATION_KEY = "fitnessai_impersonation";

interface ImpersonationState {
  adminAccessToken: string;
  adminRefreshToken: string;
  trainerEmail: string;
}

export function getImpersonationState(): ImpersonationState | null {
  if (typeof window === "undefined") return null;
  const stored = sessionStorage.getItem(IMPERSONATION_KEY);
  if (!stored) return null;
  try {
    return JSON.parse(stored) as ImpersonationState;
  } catch {
    return null;
  }
}

export function setImpersonationState(state: ImpersonationState): void {
  sessionStorage.setItem(IMPERSONATION_KEY, JSON.stringify(state));
}

export function clearImpersonationState(): void {
  sessionStorage.removeItem(IMPERSONATION_KEY);
}

export function ImpersonationBanner() {
  const [state, setState] = useState<ImpersonationState | null>(() =>
    typeof window !== "undefined" ? getImpersonationState() : null,
  );
  const [isEnding, setIsEnding] = useState(false);

  const handleEndImpersonation = useCallback(async () => {
    if (!state || isEnding) return;
    setIsEnding(true);

    try {
      await apiClient.post(API_URLS.ADMIN_IMPERSONATE_END);
    } catch (error) {
      // Log but don't block -- we still restore admin tokens
      const message = getErrorMessage(error);
      toast.error(`Warning: ${message}`);
    }

    // Restore admin tokens
    setTokens(state.adminAccessToken, state.adminRefreshToken);
    clearImpersonationState();
    setState(null);
    setIsEnding(false);

    // Clear token state then hard-navigate to avoid stale React Query cache
    window.location.href = "/admin/trainers";
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
          Viewing as {state.trainerEmail}
        </span>
        <span className="sr-only">(impersonation mode active)</span>
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
