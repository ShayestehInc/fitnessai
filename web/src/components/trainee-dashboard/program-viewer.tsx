"use client";

import { useState, useMemo } from "react";
import { Dumbbell, BedDouble, ChevronDown } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import type { TraineeViewProgram, TraineeViewScheduleDay } from "@/types/trainee-view";

const DAY_NAMES = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

interface ProgramViewerProps {
  programs: TraineeViewProgram[];
}

export function ProgramViewer({ programs }: ProgramViewerProps) {
  const activePrograms = useMemo(
    () => programs.filter((p) => p.is_active),
    [programs],
  );
  const defaultProgram = activePrograms[0] ?? programs[0];
  const [selectedProgram, setSelectedProgram] = useState<TraineeViewProgram | null>(
    defaultProgram ?? null,
  );
  const [selectedWeek, setSelectedWeek] = useState(0);

  if (!selectedProgram) {
    return (
      <Card>
        <CardContent className="py-12 text-center">
          <Dumbbell className="mx-auto mb-4 h-12 w-12 text-muted-foreground/50" />
          <p className="text-lg font-medium">No program selected</p>
          <p className="text-sm text-muted-foreground">
            Select a program to view its schedule.
          </p>
        </CardContent>
      </Card>
    );
  }

  const weeks = selectedProgram.schedule?.weeks ?? [];
  const currentWeek = weeks[selectedWeek];
  const showProgramSwitcher = programs.length > 1;

  return (
    <div className="space-y-6">
      {/* Program header */}
      <Card>
        <CardHeader>
          <div className="flex flex-wrap items-start justify-between gap-2">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <CardTitle className="text-xl">{selectedProgram.name}</CardTitle>
                {selectedProgram.is_active && (
                  <Badge variant="default" className="text-xs">
                    Active
                  </Badge>
                )}
              </div>
              {selectedProgram.description && (
                <p className="text-sm text-muted-foreground">
                  {selectedProgram.description}
                </p>
              )}
            </div>
            {showProgramSwitcher && (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="sm" className="gap-1">
                    Switch Program
                    <ChevronDown className="h-3 w-3" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  {programs.map((p) => (
                    <DropdownMenuItem
                      key={p.id}
                      onClick={() => {
                        setSelectedProgram(p);
                        setSelectedWeek(0);
                      }}
                    >
                      <span className="flex-1">{p.name}</span>
                      {p.is_active && (
                        <Badge variant="secondary" className="ml-2 text-xs">
                          Active
                        </Badge>
                      )}
                    </DropdownMenuItem>
                  ))}
                </DropdownMenuContent>
              </DropdownMenu>
            )}
          </div>
          <div className="mt-2 flex flex-wrap gap-2">
            {selectedProgram.difficulty_level && (
              <Badge variant="outline" className="capitalize">
                {selectedProgram.difficulty_level}
              </Badge>
            )}
            {selectedProgram.goal_type && (
              <Badge variant="outline" className="capitalize">
                {selectedProgram.goal_type.replace(/_/g, " ")}
              </Badge>
            )}
            {selectedProgram.duration_weeks && (
              <Badge variant="outline">
                {selectedProgram.duration_weeks} weeks
              </Badge>
            )}
          </div>
        </CardHeader>
      </Card>

      {/* Week tabs */}
      {weeks.length > 0 && (
        <div className="space-y-4">
          <div
            className="flex gap-1 overflow-x-auto pb-1"
            role="tablist"
            aria-label="Program weeks"
          >
            {weeks.map((week, idx) => (
              <button
                key={week.week_number}
                role="tab"
                aria-selected={selectedWeek === idx}
                aria-controls={`week-panel-${idx}`}
                onClick={() => setSelectedWeek(idx)}
                className={cn(
                  "shrink-0 rounded-md px-4 py-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
                  selectedWeek === idx
                    ? "bg-primary text-primary-foreground"
                    : "bg-muted text-muted-foreground hover:bg-muted/80",
                )}
              >
                Week {week.week_number}
              </button>
            ))}
          </div>

          {/* Day cards */}
          {currentWeek && (
            <div
              id={`week-panel-${selectedWeek}`}
              role="tabpanel"
              aria-label={`Week ${currentWeek.week_number} schedule`}
              className="grid gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
            >
              {currentWeek.days.map((day, dayIdx) => (
                <DayCard key={dayIdx} day={day} dayIndex={dayIdx} />
              ))}
            </div>
          )}
        </div>
      )}

      {weeks.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <Dumbbell className="mx-auto mb-4 h-12 w-12 text-muted-foreground/50" />
            <p className="text-lg font-medium">No schedule available</p>
            <p className="text-sm text-muted-foreground">
              This program doesn&apos;t have a workout schedule configured yet.
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function DayCard({
  day,
  dayIndex,
}: {
  day: TraineeViewScheduleDay;
  dayIndex: number;
}) {
  const dayName = day.name || DAY_NAMES[dayIndex] || `Day ${dayIndex + 1}`;
  const isRestDay = day.is_rest_day === true;

  return (
    <Card className={isRestDay ? "opacity-60" : undefined}>
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold">
            {DAY_NAMES[dayIndex] || `Day ${dayIndex + 1}`}
          </CardTitle>
          {isRestDay && (
            <Badge variant="secondary" className="text-xs">
              <BedDouble className="mr-1 h-3 w-3" />
              Rest
            </Badge>
          )}
        </div>
        {day.name && DAY_NAMES[dayIndex] !== day.name && (
          <p className="text-xs text-muted-foreground">{day.name}</p>
        )}
      </CardHeader>
      <CardContent>
        {isRestDay ? (
          <p className="py-2 text-center text-sm text-muted-foreground">
            Recovery day
          </p>
        ) : day.exercises.length === 0 ? (
          <p className="py-2 text-center text-sm text-muted-foreground">
            No exercises scheduled
          </p>
        ) : (
          <div className="space-y-1.5">
            {day.exercises.map((ex, i) => (
              <div
                key={`${ex.exercise_id}-${i}`}
                className="flex items-start gap-2 text-sm"
              >
                <span className="mt-0.5 shrink-0 text-xs text-muted-foreground">
                  {i + 1}.
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium">{ex.exercise_name}</p>
                  <p className="text-xs text-muted-foreground">
                    {ex.sets} sets x {ex.reps} reps
                    {ex.weight > 0 && (
                      <>
                        {" "}
                        @ {ex.weight} {ex.unit}
                      </>
                    )}
                    {ex.rest_seconds > 0 && (
                      <> &middot; {ex.rest_seconds}s rest</>
                    )}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
