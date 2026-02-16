"use client";

import { use } from "react";
import { PageHeader } from "@/components/shared/page-header";
import { ProgramBuilder } from "@/components/programs/program-builder";
import { ErrorState } from "@/components/shared/error-state";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { useProgram } from "@/hooks/use-programs";

interface EditProgramPageProps {
  params: Promise<{ id: string }>;
}

export default function EditProgramPage({ params }: EditProgramPageProps) {
  const { id } = use(params);
  const programId = parseInt(id, 10);
  const validId = !isNaN(programId) && programId > 0 ? programId : 0;

  const { data, isLoading, isError, refetch } = useProgram(validId);

  if (validId === 0) {
    return (
      <div className="space-y-6">
        <PageHeader title="Edit Program" />
        <ErrorState message="Invalid program ID" />
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader title="Edit Program" />
        <LoadingSpinner />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <div className="space-y-6">
        <PageHeader title="Edit Program" />
        <ErrorState
          message="Failed to load program"
          onRetry={() => refetch()}
        />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Edit Program"
        description={data.name}
      />
      <ProgramBuilder existingProgram={data} />
    </div>
  );
}
