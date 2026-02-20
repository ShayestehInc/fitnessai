"use client";

import { useEffect, useState } from "react";
import { Eye } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { ProfileCard } from "@/components/trainee-view/profile-card";
import { ProgramCard } from "@/components/trainee-view/program-card";
import { NutritionCard } from "@/components/trainee-view/nutrition-card";
import { WeightCard } from "@/components/trainee-view/weight-card";
import { getTrainerImpersonationState } from "@/components/layout/trainer-impersonation-banner";

export default function TraineeViewPage() {
  const [traineeName, setTraineeName] = useState<string>("");

  useEffect(() => {
    const state = getTrainerImpersonationState();
    if (state) {
      setTraineeName(state.traineeName);
    }
  }, []);

  return (
    <div className="space-y-6">
      {/* AC-19: Page title with trainee name */}
      <div className="flex items-center gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">
            Trainee View{traineeName ? ` \u2014 ${traineeName}` : ""}
          </h1>
          <p className="text-sm text-muted-foreground">
            Read-only view of what this trainee sees in the app
          </p>
        </div>
        {/* AC-20: Read-Only badge */}
        <Badge
          variant="outline"
          className="ml-auto flex items-center gap-1 border-amber-500 text-amber-600"
        >
          <Eye className="h-3 w-3" aria-hidden="true" />
          Read-Only
        </Badge>
      </div>

      {/* AC-13: 4 read-only sections, responsive grid */}
      <div className="grid gap-6 lg:grid-cols-2">
        <ProfileCard />
        <ProgramCard />
        <NutritionCard />
        <WeightCard />
      </div>
    </div>
  );
}
