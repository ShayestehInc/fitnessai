"use client";

import { PageHeader } from "@/components/shared/page-header";
import { ProgramBuilder } from "@/components/programs/program-builder";

export default function NewProgramPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Create Program"
        description="Build a new workout program template"
      />
      <ProgramBuilder />
    </div>
  );
}
