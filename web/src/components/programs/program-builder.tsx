"use client";

import { useState, useCallback, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { Loader2, Save } from "lucide-react";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { WeekEditor } from "./week-editor";
import { useCreateProgram, useUpdateProgram } from "@/hooks/use-programs";
import { ApiError } from "@/lib/api-client";
import {
  DAY_NAMES,
  DifficultyLevel,
  DIFFICULTY_LABELS,
  GoalType,
  GOAL_LABELS,
  type ProgramTemplate,
  type Schedule,
  type ScheduleWeek,
  type CreateProgramPayload,
  type UpdateProgramPayload,
} from "@/types/program";

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

function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    if (typeof error.body === "object" && error.body !== null) {
      const messages = Object.entries(error.body as Record<string, unknown>)
        .map(([key, value]) => {
          if (Array.isArray(value)) return `${key}: ${value.join(", ")}`;
          return `${key}: ${value}`;
        })
        .join("; ");
      if (messages) return messages;
    }
    return error.statusText;
  }
  return "An unexpected error occurred";
}

interface ProgramBuilderProps {
  existingProgram?: ProgramTemplate;
}

export function ProgramBuilder({ existingProgram }: ProgramBuilderProps) {
  const router = useRouter();
  const isEditing = Boolean(existingProgram);
  const isDirtyRef = useRef(false);

  const [name, setName] = useState(existingProgram?.name ?? "");
  const [description, setDescription] = useState(
    existingProgram?.description ?? "",
  );
  const [durationWeeks, setDurationWeeks] = useState(
    existingProgram?.duration_weeks ?? 4,
  );
  const [difficultyLevel, setDifficultyLevel] = useState<
    DifficultyLevel | ""
  >(existingProgram?.difficulty_level ?? "");
  const [goalType, setGoalType] = useState<GoalType | "">(
    existingProgram?.goal_type ?? "",
  );
  const [schedule, setSchedule] = useState<Schedule>(
    existingProgram?.schedule_template ?? createEmptySchedule(4),
  );
  const [activeWeek, setActiveWeek] = useState("1");

  const createMutation = useCreateProgram();
  const updateMutation = useUpdateProgram(existingProgram?.id ?? 0);
  const isSaving = createMutation.isPending || updateMutation.isPending;

  // Track dirty state
  useEffect(() => {
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

  // Sync schedule weeks when duration changes
  const handleDurationChange = useCallback(
    (newDuration: number) => {
      const clamped = Math.max(1, Math.min(52, newDuration));
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

      // If active week tab exceeds new duration, reset to last week
      if (parseInt(activeWeek) > clamped) {
        setActiveWeek(String(clamped));
      }
    },
    [activeWeek],
  );

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
    if (!name.trim()) {
      toast.error("Program name is required");
      return;
    }

    const payload: CreateProgramPayload | UpdateProgramPayload = {
      name: name.trim(),
      description: description.trim(),
      duration_weeks: durationWeeks,
      schedule_template: schedule,
      difficulty_level: difficultyLevel || undefined,
      goal_type: goalType || undefined,
    };

    try {
      if (isEditing) {
        await updateMutation.mutateAsync(payload as UpdateProgramPayload);
        isDirtyRef.current = false;
        toast.success("Program updated");
      } else {
        await createMutation.mutateAsync(payload as CreateProgramPayload);
        isDirtyRef.current = false;
        toast.success("Program created");
        router.push("/programs");
      }
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  };

  return (
    <div className="space-y-6">
      {/* Metadata Section */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Program Details</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="program-name">
                Name <span className="text-destructive">*</span>
              </Label>
              <Input
                id="program-name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g., 12-Week Strength Program"
                maxLength={100}
                required
              />
            </div>

            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="program-description">Description</Label>
              <textarea
                id="program-description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Brief description of the program..."
                maxLength={500}
                rows={3}
                className="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              />
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
            </div>

            <div className="space-y-2">
              <Label htmlFor="difficulty-level">Difficulty Level</Label>
              <select
                id="difficulty-level"
                value={difficultyLevel}
                onChange={(e) =>
                  setDifficultyLevel(e.target.value as DifficultyLevel | "")
                }
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
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
                onChange={(e) =>
                  setGoalType(e.target.value as GoalType | "")
                }
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              >
                <option value="">Select goal...</option>
                {Object.entries(GOAL_LABELS).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Schedule Editor */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Weekly Schedule</CardTitle>
        </CardHeader>
        <CardContent>
          <Tabs value={activeWeek} onValueChange={setActiveWeek}>
            <TabsList className="mb-4 flex flex-wrap gap-1">
              {schedule.weeks.map((week) => (
                <TabsTrigger
                  key={week.week_number}
                  value={String(week.week_number)}
                  className="text-xs"
                >
                  Week {week.week_number}
                </TabsTrigger>
              ))}
            </TabsList>

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
      <div className="flex justify-end gap-3">
        <Button
          type="button"
          variant="outline"
          onClick={() => {
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
