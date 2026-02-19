"use client";

import { useCallback, useState } from "react";
import { Loader2, Trophy } from "lucide-react";
import { toast } from "sonner";
import {
  useLeaderboardSettings,
  useUpdateLeaderboardSetting,
  type LeaderboardSetting,
} from "@/hooks/use-leaderboard-settings";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { getErrorMessage } from "@/lib/error-utils";

const METRIC_LABELS: Record<string, string> = {
  workout_count: "Workout Count",
  streak: "Streak",
};

const TIME_PERIOD_LABELS: Record<string, string> = {
  weekly: "Weekly",
  monthly: "Monthly",
};

function settingKey(setting: LeaderboardSetting): string {
  return `${setting.metric_type}:${setting.time_period}`;
}

function settingDisplayName(setting: LeaderboardSetting): string {
  const metric = METRIC_LABELS[setting.metric_type] ?? setting.metric_type;
  const period = TIME_PERIOD_LABELS[setting.time_period] ?? setting.time_period;
  return `${metric} (${period})`;
}

export function LeaderboardSection() {
  const { data: settings, isLoading } = useLeaderboardSettings();
  const updateMutation = useUpdateLeaderboardSetting();
  const [pendingToggles, setPendingToggles] = useState<Set<string>>(new Set());

  const handleToggle = useCallback(
    (setting: LeaderboardSetting) => {
      const key = settingKey(setting);
      setPendingToggles((prev) => new Set(prev).add(key));
      updateMutation.mutate(
        {
          metric_type: setting.metric_type,
          time_period: setting.time_period,
          is_enabled: !setting.is_enabled,
        },
        {
          onSuccess: () => {
            toast.success(
              `${settingDisplayName(setting)} ${!setting.is_enabled ? "enabled" : "disabled"}`,
            );
          },
          onError: (err) => toast.error(getErrorMessage(err)),
          onSettled: () => {
            setPendingToggles((prev) => {
              const next = new Set(prev);
              next.delete(key);
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
            const key = settingKey(setting);
            const isPending = pendingToggles.has(key);
            return (
              <div
                key={key}
                className="flex items-center justify-between gap-4 rounded-md border p-3"
              >
                <div className="min-w-0">
                  <p className="text-sm font-medium">
                    {settingDisplayName(setting)}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {METRIC_LABELS[setting.metric_type] ?? setting.metric_type} &middot;{" "}
                    {TIME_PERIOD_LABELS[setting.time_period] ?? setting.time_period}
                  </p>
                </div>
                <Button
                  variant={setting.is_enabled ? "default" : "outline"}
                  size="sm"
                  disabled={isPending}
                  onClick={() => handleToggle(setting)}
                  className="shrink-0"
                >
                  {isPending ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : setting.is_enabled ? (
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
