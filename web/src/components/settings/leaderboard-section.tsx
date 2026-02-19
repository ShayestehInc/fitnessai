"use client";

import { useCallback, useEffect, useState } from "react";
import { Loader2, Trophy } from "lucide-react";
import { toast } from "sonner";
import { useLeaderboardSettings, useUpdateLeaderboardSetting } from "@/hooks/use-leaderboard-settings";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import { getErrorMessage } from "@/lib/error-utils";

interface LeaderboardSetting {
  id: number;
  metric: string;
  label: string;
  enabled: boolean;
}

const METRIC_DESCRIPTIONS: Record<string, string> = {
  workout_streak: "Consecutive days with logged workouts",
  calories_adherence: "Percentage of days meeting calorie goals",
  protein_adherence: "Percentage of days meeting protein goals",
  workout_volume: "Total sets x reps x weight over time",
  check_in_streak: "Consecutive days with weight check-ins",
};

export function LeaderboardSection() {
  const { data: settings, isLoading } = useLeaderboardSettings();
  const updateMutation = useUpdateLeaderboardSetting();
  const [pendingToggles, setPendingToggles] = useState<Set<number>>(new Set());

  const handleToggle = useCallback(
    (setting: LeaderboardSetting) => {
      setPendingToggles((prev) => new Set(prev).add(setting.id));
      updateMutation.mutate(
        { id: setting.id, enabled: !setting.enabled },
        {
          onSuccess: () => {
            toast.success(
              `${setting.label} ${!setting.enabled ? "enabled" : "disabled"}`,
            );
          },
          onError: (err) => toast.error(getErrorMessage(err)),
          onSettled: () => {
            setPendingToggles((prev) => {
              const next = new Set(prev);
              next.delete(setting.id);
              return next;
            });
          },
        },
      );
    },
    [updateMutation],
  );

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-40" />
          <Skeleton className="h-4 w-64" />
        </CardHeader>
        <CardContent className="space-y-3">
          {[1, 2, 3].map((i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
        </CardContent>
      </Card>
    );
  }

  const leaderboardSettings = (settings ?? []) as LeaderboardSetting[];

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <Trophy className="h-5 w-5 text-muted-foreground" />
          <CardTitle>Leaderboard Settings</CardTitle>
        </div>
        <CardDescription>
          Choose which metrics your trainees compete on
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {leaderboardSettings.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            No leaderboard metrics configured yet.
          </p>
        ) : (
          leaderboardSettings.map((setting) => {
            const isPending = pendingToggles.has(setting.id);
            return (
              <div
                key={setting.id}
                className="flex items-center justify-between gap-4 rounded-md border p-3"
              >
                <div className="min-w-0">
                  <p className="text-sm font-medium">{setting.label}</p>
                  <p className="text-xs text-muted-foreground">
                    {METRIC_DESCRIPTIONS[setting.metric] ?? setting.metric}
                  </p>
                </div>
                <Button
                  variant={setting.enabled ? "default" : "outline"}
                  size="sm"
                  disabled={isPending}
                  onClick={() => handleToggle(setting)}
                  className="shrink-0"
                >
                  {isPending ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : setting.enabled ? (
                    "Enabled"
                  ) : (
                    "Disabled"
                  )}
                </Button>
              </div>
            );
          })
        )}
      </CardContent>
    </Card>
  );
}
