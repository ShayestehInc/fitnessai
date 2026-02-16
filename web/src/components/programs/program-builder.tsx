"use client";

import { useState, useCallback, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { Loader2, Save, Copy } from "lucide-react";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ScrollArea, ScrollBar } from "@/components/ui/scroll-area";
import { WeekEditor } from "./week-editor";
import { useCreateProgram, useUpdateProgram } from "@/hooks/use-programs";
import { getErrorMessage } from "@/lib/error-utils";
import {
  DAY_NAMES,
  DIFFICULTY_LABELS,
  GOAL_LABELS,
  type ProgramTemplate,
  type Schedule,
  type ScheduleWeek,
  type DifficultyLevel,
  type GoalType,
} from "@/types/program";

const NAME_MAX_LENGTH = 100;
const DESCRIPTION_MAX_LENGTH = 500;

function createEmptyWeek(weekNumber: number): ScheduleWeek {
  return {
    week_number: weekNumber,
    days: DAY_NAMES.map((day) => ({
      day,
      name: "Rest",
      is_rest_day: true,
      exercises: [],
    })),
  };
}

function createEmptySchedule(durationWeeks: number): Schedule {
  return {
    weeks: Array.from({ length: durationWeeks }, (_, i) =>
      createEmptyWeek(i + 1),
    ),
  };
}

function reconcileSchedule(
  schedule: Schedule | null,
  durationWeeks: number,
): Schedule {
  if (!schedule || schedule.weeks.length === 0) {
    return createEmptySchedule(durationWeeks);
  }
  if (schedule.weeks.length < durationWeeks) {
    const extra = Array.from(
      { length: durationWeeks - schedule.weeks.length },
      (_, i) => createEmptyWeek(schedule.weeks.length + i + 1),
    );
    return { weeks: [...schedule.weeks, ...extra] };
  }
  if (schedule.weeks.length > durationWeeks) {
    return { weeks: schedule.weeks.slice(0, durationWeeks) };
  }
  return schedule;
}

interface ProgramBuilderProps {
  existingProgram?: ProgramTemplate;
}

export function ProgramBuilder({ existingProgram }: ProgramBuilderProps) {
  const router = useRouter();
  const isEditing = Boolean(existingProgram);
  const isDirtyRef = useRef(false);
  const hasMountedRef = useRef(false);
  const savingRef = useRef(false);

  const initialDuration = existingProgram?.duration_weeks ?? 4;
  const [name, setName] = useState(existingProgram?.name ?? "");
  const [description, setDescription] = useState(
    existingProgram?.description ?? "",
  );
  const [durationWeeks, setDurationWeeks] = useState(initialDuration);
  const [difficultyLevel, setDifficultyLevel] = useState<
    DifficultyLevel | ""
  >(existingProgram?.difficulty_level ?? "");
  const [goalType, setGoalType] = useState<GoalType | "">(
    existingProgram?.goal_type ?? "",
  );
  const [schedule, setSchedule] = useState<Schedule>(() =>
    reconcileSchedule(
      existingProgram?.schedule_template ?? null,
      initialDuration,
    ),
  );
  const [activeWeek, setActiveWeek] = useState("1");

  const createMutation = useCreateProgram();
  const updateMutation = useUpdateProgram(existingProgram?.id ?? 0);
  const isSaving = createMutation.isPending || updateMutation.isPending;

  // Track dirty state — skip initial mount
  useEffect(() => {
    if (!hasMountedRef.current) {
      hasMountedRef.current = true;
      return;
    }
    isDirtyRef.current = true;
  }, [name, description, durationWeeks, difficultyLevel, goalType, schedule]);

  // Warn on navigation away with unsaved changes
  useEffect(() => {
    const handler = (e: BeforeUnloadEvent) => {
      if (isDirtyRef.current) {
        e.preventDefault();
      }
    };
    window.addEventListener("beforeunload", handler);
    return () => window.removeEventListener("beforeunload", handler);
  }, []);

  // Keep a ref to the latest save handler for keyboard shortcut
  const handleSaveRef = useRef<() => void>(() => {});

  // Check if weeks being removed have any exercise data
  const weeksHaveData = useCallback(
    (startIndex: number, endIndex: number): boolean => {
      return schedule.weeks.slice(startIndex, endIndex).some((week) =>
        week.days.some(
          (day) => !day.is_rest_day || day.exercises.length > 0,
        ),
      );
    },
    [schedule],
  );

  // Sync schedule weeks when duration changes
  const handleDurationChange = useCallback(
    (newDuration: number) => {
      const clamped = Math.max(1, Math.min(52, newDuration));

      // Warn when reducing weeks that have exercise data
      if (clamped < durationWeeks && weeksHaveData(clamped, durationWeeks)) {
        const weeksToRemove = durationWeeks - clamped;
        const confirmed = window.confirm(
          `Reducing to ${clamped} week${clamped !== 1 ? "s" : ""} will remove ${weeksToRemove} week${weeksToRemove !== 1 ? "s" : ""} that contain exercise data. This cannot be undone. Continue?`,
        );
        if (!confirmed) return;
      }

      setDurationWeeks(clamped);

      setSchedule((prev) => {
        const currentWeeks = prev.weeks;
        if (clamped > currentWeeks.length) {
          const newWeeks = Array.from(
            { length: clamped - currentWeeks.length },
            (_, i) => createEmptyWeek(currentWeeks.length + i + 1),
          );
          return { weeks: [...currentWeeks, ...newWeeks] };
        }
        if (clamped < currentWeeks.length) {
          return { weeks: currentWeeks.slice(0, clamped) };
        }
        return prev;
      });

      if (parseInt(activeWeek) > clamped) {
        setActiveWeek(String(clamped));
      }
    },
    [activeWeek, durationWeeks, weeksHaveData],
  );

  // Copy current week's schedule to all other weeks
  const copyWeekToAll = useCallback(() => {
    const currentWeekIndex = parseInt(activeWeek) - 1;
    const sourceWeek = schedule.weeks[currentWeekIndex];
    if (!sourceWeek) return;

    const confirmed = window.confirm(
      `Copy Week ${activeWeek}'s schedule to all other weeks? This will overwrite their existing exercises.`,
    );
    if (!confirmed) return;

    setSchedule((prev) => ({
      weeks: prev.weeks.map((week, idx) => {
        if (idx === currentWeekIndex) return week;
        return {
          ...week,
          days: sourceWeek.days.map((day, dayIdx) => ({
            ...day,
            day: week.days[dayIdx]?.day ?? day.day,
          })),
        };
      }),
    }));
    toast.success(`Week ${activeWeek} copied to all other weeks`);
  }, [activeWeek, schedule]);

  const updateWeek = useCallback(
    (weekIndex: number, updated: ScheduleWeek) => {
      setSchedule((prev) => {
        const weeks = [...prev.weeks];
        weeks[weekIndex] = updated;
        return { weeks };
      });
    },
    [],
  );

  const handleSave = async () => {
    if (savingRef.current) return;
    if (!name.trim()) {
      toast.error("Program name is required");
      return;
    }

    savingRef.current = true;

    const basePayload = {
      name: name.trim(),
      description: description.trim(),
      duration_weeks: durationWeeks,
      schedule_template: schedule,
      difficulty_level: difficultyLevel || undefined,
      goal_type: goalType || undefined,
    };

    try {
      if (isEditing) {
        await updateMutation.mutateAsync(basePayload);
        isDirtyRef.current = false;
        toast.success("Program updated");
      } else {
        await createMutation.mutateAsync(basePayload);
        isDirtyRef.current = false;
        toast.success("Program created");
        router.push("/programs");
      }
    } catch (error) {
      toast.error(getErrorMessage(error));
    } finally {
      savingRef.current = false;
    }
  };

  // Update save ref after handleSave is defined
  handleSaveRef.current = handleSave;

  // Ctrl+S / Cmd+S keyboard shortcut to save
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "s") {
        e.preventDefault();
        handleSaveRef.current();
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

  return (
    <div className="space-y-6">
      {/* Metadata Section */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Program Details</CardTitle>
          <CardDescription>
            Define the basic information for this program template.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <fieldset disabled={isSaving} className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="program-name">
                Name <span className="text-destructive">*</span>
              </Label>
              <Input
                id="program-name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g., 12-Week Strength Program"
                maxLength={NAME_MAX_LENGTH}
                required
                aria-describedby="program-name-count"
                aria-invalid={name.trim().length === 0 && name.length > 0 ? true : undefined}
              />
              <div className="flex items-center justify-between">
                {name.length > 0 && name.trim().length === 0 && (
                  <p className="text-xs text-destructive" role="alert">
                    Name cannot be only whitespace
                  </p>
                )}
                <p
                  id="program-name-count"
                  className={`ml-auto text-xs ${
                    name.length > NAME_MAX_LENGTH * 0.9
                      ? "text-amber-600 dark:text-amber-400"
                      : "text-muted-foreground"
                  }`}
                >
                  {name.length}/{NAME_MAX_LENGTH}
                </p>
              </div>
            </div>

            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="program-description">Description</Label>
              <textarea
                id="program-description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Brief description of the program..."
                maxLength={DESCRIPTION_MAX_LENGTH}
                rows={3}
                aria-describedby="program-description-count"
                className="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50"
              />
              <p
                id="program-description-count"
                className={`text-right text-xs ${
                  description.length > DESCRIPTION_MAX_LENGTH * 0.9
                    ? "text-amber-600 dark:text-amber-400"
                    : "text-muted-foreground"
                }`}
              >
                {description.length}/{DESCRIPTION_MAX_LENGTH}
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="duration-weeks">Duration (weeks)</Label>
              <Input
                id="duration-weeks"
                type="number"
                min={1}
                max={52}
                step={1}
                value={durationWeeks}
                onChange={(e) =>
                  handleDurationChange(parseInt(e.target.value) || 1)
                }
              />
              <p className="text-xs text-muted-foreground">
                Between 1 and 52 weeks
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="difficulty-level">Difficulty Level</Label>
              <select
                id="difficulty-level"
                value={difficultyLevel}
                onChange={(e) => {
                  const val = e.target.value;
                  setDifficultyLevel(
                    val in DIFFICULTY_LABELS
                      ? (val as DifficultyLevel)
                      : "",
                  );
                }}
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50"
              >
                <option value="">Select difficulty...</option>
                {Object.entries(DIFFICULTY_LABELS).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="goal-type">Goal Type</Label>
              <select
                id="goal-type"
                value={goalType}
                onChange={(e) => {
                  const val = e.target.value;
                  setGoalType(
                    val in GOAL_LABELS ? (val as GoalType) : "",
                  );
                }}
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50"
              >
                <option value="">Select goal...</option>
                {Object.entries(GOAL_LABELS).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>
          </fieldset>
        </CardContent>
      </Card>

      {/* Schedule Editor */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Weekly Schedule</CardTitle>
          <CardDescription>
            Configure exercises for each day of each week. Click a week tab to edit its schedule.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={activeWeek} onValueChange={setActiveWeek}>
            <ScrollArea className="mb-4 w-full">
              <TabsList className="inline-flex w-max gap-1">
                {schedule.weeks.map((week) => (
                  <TabsTrigger
                    key={week.week_number}
                    value={String(week.week_number)}
                    className="text-xs"
                    aria-label={`Week ${week.week_number} of ${schedule.weeks.length}`}
                  >
                    Week {week.week_number}
                  </TabsTrigger>
                ))}
              </TabsList>
              <ScrollBar orientation="horizontal" />
            </ScrollArea>

            {schedule.weeks.length > 1 && (
              <div className="mb-4 flex justify-end">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="gap-1.5 text-xs"
                  onClick={copyWeekToAll}
                >
                  <Copy className="h-3.5 w-3.5" aria-hidden="true" />
                  Copy Week {activeWeek} to All
                </Button>
              </div>
            )}

            {schedule.weeks.map((week, idx) => (
              <TabsContent
                key={week.week_number}
                value={String(week.week_number)}
              >
                <WeekEditor
                  week={week}
                  onUpdate={(updated) => updateWeek(idx, updated)}
                />
              </TabsContent>
            ))}
          </Tabs>
        </CardContent>
      </Card>

      {/* Save Button */}
      <div className="flex items-center justify-end gap-3">
        <kbd className="hidden text-xs text-muted-foreground sm:inline">
          {typeof navigator !== "undefined" &&
          /Mac|iPod|iPhone|iPad/.test(navigator.userAgent)
            ? "\u2318"
            : "Ctrl"}
          +S to save
        </kbd>
        <Button
          type="button"
          variant="outline"
          onClick={() => {
            if (isDirtyRef.current) {
              const confirmed = window.confirm(
                "You have unsaved changes. Discard and go back?",
              );
              if (!confirmed) return;
            }
            isDirtyRef.current = false;
            router.push("/programs");
          }}
        >
          Cancel
        </Button>
        <Button
          type="button"
          onClick={handleSave}
          disabled={isSaving || !name.trim()}
        >
          {isSaving ? (
            <>
              <Loader2
                className="mr-2 h-4 w-4 animate-spin"
                aria-hidden="true"
              />
              Saving...
            </>
          ) : (
            <>
              <Save className="mr-2 h-4 w-4" aria-hidden="true" />
              {isEditing ? "Update Program" : "Save Template"}
            </>
          )}
        </Button>
      </div>
    </div>
  );
}
