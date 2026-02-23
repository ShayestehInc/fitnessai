"use client";

import {
  DifficultyLevel,
  DIFFICULTY_LABELS,
  GoalType,
  GOAL_LABELS,
  DAY_NAMES,
  type SplitType,
  type CustomDayConfig,
} from "@/types/program";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { CustomDayConfigurator } from "./custom-day-config";

const SHORT_DAY_LABELS: Record<string, string> = {
  Monday: "Mon",
  Tuesday: "Tue",
  Wednesday: "Wed",
  Thursday: "Thu",
  Friday: "Fri",
  Saturday: "Sat",
  Sunday: "Sun",
};

interface ConfigStepProps {
  splitType: SplitType;
  difficulty: DifficultyLevel | null;
  goal: GoalType | null;
  durationWeeks: number;
  trainingDays: string[];
  customDayConfig: CustomDayConfig[];
  onDifficultyChange: (d: DifficultyLevel) => void;
  onGoalChange: (g: GoalType) => void;
  onDurationChange: (w: number) => void;
  onTrainingDaysChange: (days: string[]) => void;
  onCustomDayConfigChange: (configs: CustomDayConfig[]) => void;
}

export function ConfigStep({
  splitType,
  difficulty,
  goal,
  durationWeeks,
  trainingDays,
  customDayConfig,
  onDifficultyChange,
  onGoalChange,
  onDurationChange,
  onTrainingDaysChange,
  onCustomDayConfigChange,
}: ConfigStepProps) {
  const difficulties = Object.values(DifficultyLevel);
  const goals = Object.values(GoalType);

  const toggleDay = (day: string) => {
    if (trainingDays.includes(day)) {
      if (trainingDays.length <= 2) return; // minimum 2 training days
      onTrainingDaysChange(trainingDays.filter((d) => d !== day));
    } else {
      if (trainingDays.length >= 7) return; // max 7
      onTrainingDaysChange([...trainingDays, day]);
    }
  };

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

      {/* Duration */}
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
          className="max-w-[200px]"
        />
        <p className="text-xs text-muted-foreground">Between 1 and 52 weeks</p>
      </div>

      {/* Training Day Picker */}
      <fieldset className="space-y-2">
        <Label asChild>
          <legend>Training Days</legend>
        </Label>
        <p className="text-xs text-muted-foreground">
          Select which days you want to train. Unselected days will be rest days.
        </p>
        <div className="flex gap-1.5" role="group" aria-label="Training days">
          {DAY_NAMES.map((day) => {
            const isSelected = trainingDays.includes(day);
            return (
              <button
                key={day}
                type="button"
                role="checkbox"
                aria-checked={isSelected}
                aria-label={`${day}${isSelected ? " (training day)" : " (rest day)"}`}
                className={cn(
                  "flex h-11 w-11 items-center justify-center rounded-lg border text-sm font-medium transition-all",
                  "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                  isSelected
                    ? "border-primary bg-primary text-primary-foreground shadow-sm"
                    : "border-border bg-muted/40 text-muted-foreground hover:bg-muted",
                )}
                onClick={() => toggleDay(day)}
              >
                {SHORT_DAY_LABELS[day]}
              </button>
            );
          })}
        </div>
        <p className="text-xs text-muted-foreground">
          {trainingDays.length} training day{trainingDays.length !== 1 ? "s" : ""} / {7 - trainingDays.length} rest day{(7 - trainingDays.length) !== 1 ? "s" : ""}
        </p>
      </fieldset>

      {/* Custom day config (only for custom split) */}
      {splitType === "custom" && (
        <CustomDayConfigurator
          trainingDays={trainingDays.length}
          config={customDayConfig}
          onChange={onCustomDayConfigChange}
        />
      )}
    </div>
  );
}
