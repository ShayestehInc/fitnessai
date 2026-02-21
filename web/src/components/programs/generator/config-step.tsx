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
import { Input } from "@/components/ui/input";
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
      <fieldset className="space-y-2">
        <Label asChild>
          <legend>Difficulty Level</legend>
        </Label>
        <div className="flex flex-wrap gap-2" role="radiogroup" aria-label="Difficulty Level">
          {difficulties.map((d, i) => (
            <Badge
              key={d}
              variant={difficulty === d ? "default" : "outline"}
              className={cn(
                "cursor-pointer px-3 py-1.5 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                difficulty === d && "ring-2 ring-primary/20",
              )}
              role="radio"
              aria-checked={difficulty === d}
              tabIndex={difficulty === d ? 0 : (difficulty === null && i === 0) ? 0 : -1}
              onClick={() => onDifficultyChange(d)}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  onDifficultyChange(d);
                } else if (e.key === "ArrowRight" || e.key === "ArrowDown") {
                  e.preventDefault();
                  const next = difficulties[(i + 1) % difficulties.length];
                  onDifficultyChange(next);
                } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
                  e.preventDefault();
                  const prev = difficulties[(i - 1 + difficulties.length) % difficulties.length];
                  onDifficultyChange(prev);
                }
              }}
            >
              {DIFFICULTY_LABELS[d]}
            </Badge>
          ))}
        </div>
      </fieldset>

      {/* Goal */}
      <fieldset className="space-y-2">
        <Label asChild>
          <legend>Training Goal</legend>
        </Label>
        <div className="flex flex-wrap gap-2" role="radiogroup" aria-label="Training Goal">
          {goals.map((g, i) => (
            <Badge
              key={g}
              variant={goal === g ? "default" : "outline"}
              className={cn(
                "cursor-pointer px-3 py-1.5 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                goal === g && "ring-2 ring-primary/20",
              )}
              role="radio"
              aria-checked={goal === g}
              tabIndex={goal === g ? 0 : (goal === null && i === 0) ? 0 : -1}
              onClick={() => onGoalChange(g)}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  onGoalChange(g);
                } else if (e.key === "ArrowRight" || e.key === "ArrowDown") {
                  e.preventDefault();
                  const next = goals[(i + 1) % goals.length];
                  onGoalChange(next);
                } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
                  e.preventDefault();
                  const prev = goals[(i - 1 + goals.length) % goals.length];
                  onGoalChange(prev);
                }
              }}
            >
              {GOAL_LABELS[g]}
            </Badge>
          ))}
        </div>
      </fieldset>

      {/* Duration + Days Per Week */}
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="duration-weeks">Duration (weeks)</Label>
          <Input
            id="duration-weeks"
            type="number"
            min={1}
            max={52}
            step={1}
            value={durationWeeks}
            onChange={(e) => onDurationChange(Math.max(1, Math.min(52, Math.round(Number(e.target.value)) || 1)))}
          />
          <p className="text-xs text-muted-foreground">Between 1 and 52 weeks</p>
        </div>
        <div className="space-y-2">
          <Label htmlFor="days-per-week">Training days per week</Label>
          <Input
            id="days-per-week"
            type="number"
            min={2}
            max={7}
            step={1}
            value={trainingDaysPerWeek}
            onChange={(e) => onDaysChange(Math.max(2, Math.min(7, Math.round(Number(e.target.value)) || 2)))}
          />
          <p className="text-xs text-muted-foreground">Between 2 and 7 days</p>
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
