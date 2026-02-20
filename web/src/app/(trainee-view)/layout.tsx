"use client";

import { useEffect, useState } from "react";
import { Loader2 } from "lucide-react";
import { TrainerImpersonationBanner, getTrainerImpersonationState } from "@/components/layout/trainer-impersonation-banner";
import type { TrainerImpersonationState } from "@/types/trainee-view";

export default function TraineeViewLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [impersonationState, setImpersonationState] =
    useState<TrainerImpersonationState | null>(null);
  const [isChecking, setIsChecking] = useState(true);

  useEffect(() => {
    // Guard: redirect to trainer dashboard if no impersonation state
    const state = getTrainerImpersonationState();
    if (!state) {
      window.location.href = "/dashboard";
      return;
    }
    setImpersonationState(state);
    setIsChecking(false);
  }, []);

  if (isChecking || !impersonationState) {
    return (
      <div
        className="flex min-h-screen items-center justify-center"
        role="status"
        aria-label="Loading trainee view"
      >
        <Loader2
          className="h-8 w-8 animate-spin text-muted-foreground"
          aria-hidden="true"
        />
        <span className="sr-only">Loading trainee view...</span>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen flex-col">
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-primary focus:px-4 focus:py-2 focus:text-primary-foreground focus:shadow-lg"
      >
        Skip to main content
      </a>
      <TrainerImpersonationBanner />
      <main
        className="flex-1 overflow-auto px-4 py-6 lg:px-6"
        id="main-content"
      >
        <div className="mx-auto max-w-5xl">{children}</div>
      </main>
    </div>
  );
}
