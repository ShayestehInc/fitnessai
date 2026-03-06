"use client";

import { useState } from "react";
import { ClipboardList } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ChangeProgramPanel } from "./change-program-panel";

interface AssignProgramActionProps {
  traineeId: number;
  traineeName: string;
  currentProgramId?: number;
}

export function AssignProgramAction({
  traineeId,
  traineeName,
  currentProgramId,
}: AssignProgramActionProps) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <Button variant="outline" size="sm" onClick={() => setOpen(true)}>
        <ClipboardList className="mr-2 h-4 w-4" />
        {currentProgramId ? "Change Program" : "Assign Program"}
      </Button>
      <ChangeProgramPanel
        traineeId={traineeId}
        traineeName={traineeName}
        currentProgramId={currentProgramId}
        open={open}
        onOpenChange={setOpen}
      />
    </>
  );
}
