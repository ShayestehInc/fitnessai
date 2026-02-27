"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { DataTable, type Column } from "@/components/shared/data-table";
import { RiskTierBadge } from "./risk-tier-badge";
import { EngagementBar } from "./engagement-bar";
import type { TraineeEngagement } from "@/types/retention";

interface AtRiskTraineeTableProps {
  trainees: TraineeEngagement[];
  onRowClick?: (trainee: TraineeEngagement) => void;
}

function formatLastActive(days: number | null): string {
  if (days === null) return "Never";
  if (days === 0) return "Today";
  if (days === 1) return "Yesterday";
  return `${days}d ago`;
}

const columns: Column<TraineeEngagement>[] = [
  {
    key: "trainee_name",
    header: "Trainee",
    cell: (row) => (
      <div>
        <p className="font-medium">{row.trainee_name}</p>
        <p className="text-xs text-muted-foreground">{row.trainee_email}</p>
      </div>
    ),
  },
  {
    key: "engagement_score",
    header: "Engagement",
    cell: (row) => <EngagementBar value={row.engagement_score} />,
  },
  {
    key: "churn_risk_score",
    header: "Churn Risk",
    cell: (row) => (
      <span className="text-sm tabular-nums font-medium">
        {row.churn_risk_score.toFixed(0)}
      </span>
    ),
  },
  {
    key: "risk_tier",
    header: "Risk Level",
    cell: (row) => <RiskTierBadge tier={row.risk_tier} />,
  },
  {
    key: "days_since_last_activity",
    header: "Last Active",
    cell: (row) => (
      <span className="text-sm text-muted-foreground">
        {formatLastActive(row.days_since_last_activity)}
      </span>
    ),
    className: "hidden sm:table-cell",
  },
  {
    key: "workout_consistency",
    header: "Workout %",
    cell: (row) => (
      <span className="text-sm tabular-nums text-muted-foreground">
        {row.workout_consistency.toFixed(0)}%
      </span>
    ),
    className: "hidden md:table-cell",
  },
  {
    key: "nutrition_consistency",
    header: "Nutrition %",
    cell: (row) => (
      <span className="text-sm tabular-nums text-muted-foreground">
        {row.nutrition_consistency.toFixed(0)}%
      </span>
    ),
    className: "hidden md:table-cell",
  },
];

export function AtRiskTraineeTable({
  trainees,
  onRowClick,
}: AtRiskTraineeTableProps) {
  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-base">
          Trainee Risk Overview ({trainees.length})
        </CardTitle>
      </CardHeader>
      <CardContent>
        <DataTable
          columns={columns}
          data={trainees}
          keyExtractor={(row) => row.trainee_id}
          onRowClick={onRowClick}
          rowAriaLabel={(row) =>
            `${row.trainee_name}, ${row.risk_tier} risk, engagement ${row.engagement_score.toFixed(0)}%`
          }
        />
      </CardContent>
    </Card>
  );
}
