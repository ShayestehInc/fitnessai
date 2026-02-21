"use client";

import {
  DifficultyLevel,
  DIFFICULTY_LABELS,
  GoalType,
  GOAL_LABELS,
  type SplitType,
  type CustomDayConfig,
} from "@/types/program";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { CustomDayConfigurator } from "./custom-day-config";

interface ConfigStepProps {
  splitType: SplitType;
  difficulty: DifficultyLevel | null;
  goal: GoalType | null;
  durationWeeks: number;
  trainingDaysPerWeek: number;
  customDayConfig: CustomDayConfig[];
  onDifficultyChange: (d: DifficultyLevel) => void;
  onGoalChange: (g: GoalType) => void;
  onDurationChange: (w: number) => void;
  onDaysChange: (d: number) => void;
  onCustomDayConfigChange: (configs: CustomDayConfig[]) => void;
}

export function ConfigStep({
  splitType,
  difficulty,
  goal,
  durationWeeks,
  trainingDaysPerWeek,
  customDayConfig,
  onDifficultyChange,
  onGoalChange,
  onDurationChange,
  onDaysChange,
  onCustomDayConfigChange,
}: ConfigStepProps) {
  const difficulties = Object.values(DifficultyLevel);
  const goals = Object.values(GoalType);

  return (
    <div className="space-y-6">
      <h3 className="text-lg font-semibold">Configure your program</h3>

      {/* Difficulty */}
      <div className="space-y-2">
        <Label>Difficulty Level</Label>
        <div className="flex flex-wrap gap-2">
          {difficulties.map((d) => (
            <Badge
              key={d}
              variant={difficulty === d ? "default" : "outline"}
              className={cn(
                "cursor-pointer px-3 py-1.5 text-sm",
                difficulty === d && "ring-2 ring-primary/20",
              )}
              role="radio"
              aria-checked={difficulty === d}
              tabIndex={0}
              onClick={() => onDifficultyChange(d)}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  onDifficultyChange(d);
                }
              }}
            >
              {DIFFICULTY_LABELS[d]}
            </Badge>
          ))}
        </div>
      </div>

      {/* Goal */}
      <div className="space-y-2">
        <Label>Training Goal</Label>
        <div className="flex flex-wrap gap-2">
          {goals.map((g) => (
            <Badge
              key={g}
              variant={goal === g ? "default" : "outline"}
              className={cn(
                "cursor-pointer px-3 py-1.5 text-sm",
                goal === g && "ring-2 ring-primary/20",
              )}
              role="radio"
              aria-checked={goal === g}
              tabIndex={0}
              onClick={() => onGoalChange(g)}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  onGoalChange(g);
                }
              }}
            >
              {GOAL_LABELS[g]}
            </Badge>
          ))}
        </div>
      </div>

      {/* Duration + Days Per Week */}
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="duration-weeks">Duration (weeks)</Label>
          <input
            id="duration-weeks"
            type="number"
            min={1}
            max={52}
            value={durationWeeks}
            onChange={(e) => onDurationChange(Math.max(1, Math.min(52, Number(e.target.value) || 1)))}
            className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="days-per-week">Training days per week</Label>
          <input
            id="days-per-week"
            type="number"
            min={2}
            max={7}
            value={trainingDaysPerWeek}
            onChange={(e) => onDaysChange(Math.max(2, Math.min(7, Number(e.target.value) || 2)))}
            className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          />
        </div>
      </div>

      {/* Custom day config (only for custom split) */}
      {splitType === "custom" && (
        <CustomDayConfigurator
          trainingDays={trainingDaysPerWeek}
          config={customDayConfig}
          onChange={onCustomDayConfigChange}
        />
      )}
    </div>
  );
}
