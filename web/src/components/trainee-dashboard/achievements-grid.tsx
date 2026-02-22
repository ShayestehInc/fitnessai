"use client";

import { Trophy, Lock } from "lucide-react";
import {
  Card,
  CardContent,
} from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { cn } from "@/lib/utils";
import type { Achievement } from "@/types/trainee-dashboard";

interface AchievementsGridProps {
  achievements: Achievement[];
}

export function AchievementsGrid({ achievements }: AchievementsGridProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {achievements.map((achievement) => (
        <AchievementCard key={achievement.id} achievement={achievement} />
      ))}
    </div>
  );
}

function AchievementCard({ achievement }: { achievement: Achievement }) {
  const progressPercentage =
    achievement.criteria_value > 0
      ? Math.min(
          (achievement.progress / achievement.criteria_value) * 100,
          100,
        )
      : 0;

  return (
    <Card
      className={!achievement.earned ? "opacity-60" : undefined}
      role="article"
      aria-label={`${achievement.name} — ${achievement.earned ? "Earned" : "Locked"}`}
    >
      <CardContent className="flex items-start gap-4 pt-6">
        <div
          className={cn(
            "flex h-12 w-12 shrink-0 items-center justify-center rounded-full",
            achievement.earned
              ? "bg-primary/10 text-primary"
              : "bg-muted text-muted-foreground",
          )}
        >
          {achievement.earned ? (
            <Trophy className="h-6 w-6" aria-hidden="true" />
          ) : (
            <Lock className="h-5 w-5" aria-hidden="true" />
          )}
        </div>
        <div className="min-w-0 flex-1">
          <h3 className="truncate font-semibold">{achievement.name}</h3>
          <p className="mt-0.5 text-sm text-muted-foreground">
            {achievement.description}
          </p>
          {achievement.earned && achievement.earned_at ? (
            <p className="mt-1.5 text-xs text-muted-foreground">
              Earned{" "}
              {new Date(achievement.earned_at).toLocaleDateString(undefined, {
                month: "short",
                day: "numeric",
                year: "numeric",
              })}
            </p>
          ) : (
            <div className="mt-2 space-y-1">
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>Progress</span>
                <span>
                  {achievement.progress} / {achievement.criteria_value}
                </span>
              </div>
              <Progress
                value={progressPercentage}
                className="h-1.5"
                aria-label={`${achievement.name} progress: ${achievement.progress} of ${achievement.criteria_value}`}
              />
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
