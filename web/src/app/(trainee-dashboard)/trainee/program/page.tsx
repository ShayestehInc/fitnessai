"use client";

import { Dumbbell } from "lucide-react";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { ProgramViewer } from "@/components/trainee-dashboard/program-viewer";
import { useTraineeDashboardPrograms } from "@/hooks/use-trainee-dashboard";
import { useLocale } from "@/providers/locale-provider";

export default function ProgramPage() {
  const { t } = useLocale();
  const { data: programs, isLoading, isError, refetch } =
    useTraineeDashboardPrograms();

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title={t("nav.myProgram")}
          description={t("workout.myProgramDesc")}
        />
        <LoadingSpinner label="Loading program..." />
      </div>
    );
  }

  if (isError) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader
            title={t("nav.myProgram")}
            description={t("workout.myProgramDesc")}
          />
          <ErrorState
            message="Failed to load your program. Please try again."
            onRetry={() => refetch()}
          />
        </div>
      </PageTransition>
    );
  }

  if (!programs?.length) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader
            title={t("nav.myProgram")}
            description={t("workout.myProgramDesc")}
          />
          <EmptyState
            icon={Dumbbell}
            title={t("workout.noProgram")}
            description={t("workout.noProgramTraineeShort")}
          />
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title={t("nav.myProgram")}
          description={t("workout.myProgramDesc")}
        />
        <ProgramViewer programs={programs} />
      </div>
    </PageTransition>
  );
}
