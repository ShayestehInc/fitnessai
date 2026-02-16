"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/shared/page-header";
import { ProgramBuilder } from "@/components/programs/program-builder";

export default function NewProgramPage() {
  return (
    <div className="space-y-6">
      <div className="space-y-4">
        <Button variant="ghost" size="sm" className="gap-1.5" asChild>
          <Link href="/programs">
            <ArrowLeft className="h-4 w-4" aria-hidden="true" />
            Back to Programs
          </Link>
        </Button>
        <PageHeader
          title="Create Program"
          description="Build a new workout program template"
        />
      </div>
      <ProgramBuilder />
    </div>
  );
}
