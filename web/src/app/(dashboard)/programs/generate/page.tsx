"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/shared/page-header";
import { ProgramGeneratorWizard } from "@/components/programs/program-generator-wizard";

export default function GenerateProgramPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Generate Program"
        description="Create a complete training program in seconds"
        actions={
          <Button variant="ghost" asChild>
            <Link href="/programs">
              <ArrowLeft className="mr-2 h-4 w-4" aria-hidden="true" />
              Back to Programs
            </Link>
          </Button>
        }
      />

      <ProgramGeneratorWizard />
    </div>
  );
}
