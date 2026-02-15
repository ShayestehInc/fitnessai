"use client";

import { BarChart3 } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { EmptyState } from "@/components/shared/empty-state";

export function TraineeProgressTab() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Progress</CardTitle>
        <CardDescription>
          Weight, volume, and adherence trends
        </CardDescription>
      </CardHeader>
      <CardContent>
        <EmptyState
          icon={BarChart3}
          title="Coming soon"
          description="Progress charts and analytics will be available in a future update."
        />
      </CardContent>
    </Card>
  );
}
