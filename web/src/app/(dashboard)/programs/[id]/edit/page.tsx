"use client";

import { use } from "react";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/shared/page-header";
import { ProgramBuilder } from "@/components/programs/program-builder";
import { ErrorState } from "@/components/shared/error-state";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { useProgram } from "@/hooks/use-programs";

function BackLink() {
  return (
    <Button variant="ghost" size="sm" className="gap-1.5" asChild>
      <Link href="/programs">
        <ArrowLeft className="h-4 w-4" aria-hidden="true" />
        Back to Programs
      </Link>
    </Button>
  );
}

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
        <div className="space-y-4">
          <BackLink />
          <PageHeader title="Edit Program" />
        </div>
        <ErrorState message="Invalid program ID" />
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="space-y-4">
          <BackLink />
          <PageHeader title="Edit Program" />
        </div>
        <LoadingSpinner label="Loading program..." />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <div className="space-y-6">
        <div className="space-y-4">
          <BackLink />
          <PageHeader title="Edit Program" />
        </div>
        <ErrorState
          message="Failed to load program"
          onRetry={() => refetch()}
        />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="space-y-4">
        <BackLink />
        <PageHeader
          title="Edit Program"
          description={data.name}
        />
      </div>
      <ProgramBuilder existingProgram={data} />
    </div>
  );
}
