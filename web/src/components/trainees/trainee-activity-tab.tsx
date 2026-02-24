"use client";

import { useState } from "react";
import { format } from "date-fns";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { useTraineeActivity } from "@/hooks/use-trainees";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";

interface TraineeActivityTabProps {
  traineeId: number;
}

const DAY_OPTIONS = [7, 14, 30] as const;

export function TraineeActivityTab({ traineeId }: TraineeActivityTabProps) {
  const [days, setDays] = useState<number>(7);
  const { data, isLoading, isError, refetch } = useTraineeActivity(
    traineeId,
    days,
  );

  return (
    <Card>
      <CardHeader>
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <CardTitle>Activity Log</CardTitle>
            <CardDescription>Daily tracking overview</CardDescription>
          </div>
          <div className="flex gap-1" role="group" aria-label="Time range filter">
            {DAY_OPTIONS.map((d) => (
              <Button
                key={d}
                variant={days === d ? "default" : "outline"}
                size="sm"
                onClick={() => setDays(d)}
                aria-label={`Show last ${d} days`}
                aria-pressed={days === d}
              >
                {d}d
              </Button>
            ))}
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <LoadingSpinner />
        ) : isError ? (
          <ErrorState
            message="Failed to load activity"
            onRetry={() => refetch()}
          />
        ) : !data || data.length === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">
            No activity data for this period
          </p>
        ) : (
          <div className="table-scroll-hint overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Workout</TableHead>
                  <TableHead>Food</TableHead>
                  <TableHead className="text-right">Calories</TableHead>
                  <TableHead className="text-right">Protein</TableHead>
                  <TableHead className="hidden text-right md:table-cell">Carbs</TableHead>
                  <TableHead className="hidden text-right md:table-cell">Fat</TableHead>
                  <TableHead>Goals</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.map((row) => (
                  <TableRow key={row.id}>
                    <TableCell className="font-medium">
                      {format(new Date(row.date), "MMM d")}
                    </TableCell>
                    <TableCell>
                      <GoalBadge hit={row.logged_workout} label="Logged" />
                    </TableCell>
                    <TableCell>
                      <GoalBadge hit={row.logged_food} label="Logged" />
                    </TableCell>
                    <TableCell className="text-right">
                      {Math.round(row.calories_consumed)}
                    </TableCell>
                    <TableCell className="text-right">
                      {Math.round(row.protein_consumed)}g
                    </TableCell>
                    <TableCell className="hidden text-right md:table-cell">
                      {Math.round(row.carbs_consumed)}g
                    </TableCell>
                    <TableCell className="hidden text-right md:table-cell">
                      {Math.round(row.fat_consumed)}g
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1">
                        <GoalBadge
                          hit={row.hit_protein_goal}
                          label="P"
                          srLabel={row.hit_protein_goal ? "Protein goal met" : "Protein goal not met"}
                        />
                        <GoalBadge
                          hit={row.hit_calorie_goal}
                          label="C"
                          srLabel={row.hit_calorie_goal ? "Calorie goal met" : "Calorie goal not met"}
                        />
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function GoalBadge({
  hit,
  label,
  srLabel,
}: {
  hit: boolean;
  label: string;
  srLabel?: string;
}) {
  return (
    <Badge
      variant="outline"
      className={cn(
        "text-xs",
        hit
          ? "border-green-500/50 bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-400"
          : "border-muted text-muted-foreground",
      )}
      aria-label={srLabel}
    >
      {hit ? label : "—"}
    </Badge>
  );
}
