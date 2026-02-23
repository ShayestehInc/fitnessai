"use client";

import { useState } from "react";
import { Dumbbell, Plus, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import { EmptyState } from "@/components/shared/empty-state";
import { ExerciseCard } from "./exercise-card";
import { ExerciseDetailDialog } from "./exercise-detail-dialog";
import { CreateExerciseDialog } from "./create-exercise-dialog";
import { MUSCLE_GROUP_LABELS, DIFFICULTY_LABELS, GOAL_LABELS, MuscleGroup } from "@/types/program";
import type { Exercise, DifficultyLevel, GoalType } from "@/types/program";

interface ExerciseListProps {
  exercises: Exercise[];
  searchValue: string;
  onSearchChange: (value: string) => void;
  muscleGroup: MuscleGroup | "";
  onMuscleGroupChange: (mg: MuscleGroup | "") => void;
  difficultyLevel: DifficultyLevel | "";
  onDifficultyChange: (dl: DifficultyLevel | "") => void;
  goal: GoalType | "";
  onGoalChange: (g: GoalType | "") => void;
}

const ALL_GROUPS = Object.entries(MUSCLE_GROUP_LABELS) as [MuscleGroup, string][];
const ALL_DIFFICULTIES = Object.entries(DIFFICULTY_LABELS) as [DifficultyLevel, string][];
const ALL_GOALS = Object.entries(GOAL_LABELS) as [GoalType, string][];

export function ExerciseList({
  exercises,
  searchValue,
  onSearchChange,
  muscleGroup,
  onMuscleGroupChange,
  difficultyLevel,
  onDifficultyChange,
  goal,
  onGoalChange,
}: ExerciseListProps) {
  const [selectedExercise, setSelectedExercise] = useState<Exercise | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);
  const [createOpen, setCreateOpen] = useState(false);

  function handleCardClick(exercise: Exercise) {
    setSelectedExercise(exercise);
    setDetailOpen(true);
  }

  return (
    <>
      <div className="space-y-4">
        {/* Search & Create */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="relative flex-1 sm:max-w-sm">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={searchValue}
              onChange={(e) => onSearchChange(e.target.value)}
              placeholder="Search exercises..."
              className="pl-9"
            />
          </div>
          <Button onClick={() => setCreateOpen(true)}>
            <Plus className="mr-2 h-4 w-4" />
            Create Exercise
          </Button>
        </div>

        {/* Muscle group filter chips */}
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => onMuscleGroupChange("")}
            className={cn(
              "rounded-full border px-3 py-1 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
              !muscleGroup
                ? "border-primary bg-primary text-primary-foreground"
                : "hover:bg-accent",
            )}
          >
            All
          </button>
          {ALL_GROUPS.map(([key, label]) => (
            <button
              key={key}
              onClick={() => onMuscleGroupChange(key)}
              className={cn(
                "rounded-full border px-3 py-1 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                muscleGroup === key
                  ? "border-primary bg-primary text-primary-foreground"
                  : "hover:bg-accent",
              )}
            >
              {label}
            </button>
          ))}
        </div>

        {/* Difficulty filter chips */}
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => onDifficultyChange("")}
            className={cn(
              "rounded-full border px-3 py-1 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
              !difficultyLevel
                ? "border-primary bg-primary text-primary-foreground"
                : "hover:bg-accent",
            )}
          >
            All Levels
          </button>
          {ALL_DIFFICULTIES.map(([key, label]) => (
            <button
              key={key}
              onClick={() => onDifficultyChange(key)}
              className={cn(
                "rounded-full border px-3 py-1 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                difficultyLevel === key
                  ? "border-primary bg-primary text-primary-foreground"
                  : "hover:bg-accent",
              )}
            >
              {label}
            </button>
          ))}
        </div>

        {/* Training goal filter chips */}
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => onGoalChange("")}
            className={cn(
              "rounded-full border px-3 py-1 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
              !goal
                ? "border-primary bg-primary text-primary-foreground"
                : "hover:bg-accent",
            )}
          >
            All Goals
          </button>
          {ALL_GOALS.map(([key, label]) => (
            <button
              key={key}
              onClick={() => onGoalChange(key)}
              className={cn(
                "rounded-full border px-3 py-1 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                goal === key
                  ? "border-primary bg-primary text-primary-foreground"
                  : "hover:bg-accent",
              )}
            >
              {label}
            </button>
          ))}
        </div>

        {/* Grid */}
        {exercises.length === 0 ? (
          <EmptyState
            icon={Dumbbell}
            title={searchValue || muscleGroup || difficultyLevel || goal ? "No exercises match your search" : "No exercises yet"}
            description={
              searchValue || muscleGroup || difficultyLevel || goal
                ? "Try adjusting your search or filters."
                : "Add your first custom exercise to get started."
            }
            action={
              !searchValue && !muscleGroup && !difficultyLevel && !goal ? (
                <Button onClick={() => setCreateOpen(true)}>
                  <Plus className="mr-2 h-4 w-4" />
                  Create Exercise
                </Button>
              ) : undefined
            }
          />
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
            {exercises.map((ex) => (
              <ExerciseCard
                key={ex.id}
                exercise={ex}
                onClick={() => handleCardClick(ex)}
              />
            ))}
          </div>
        )}
      </div>

      <ExerciseDetailDialog
        exercise={selectedExercise}
        open={detailOpen}
        onOpenChange={setDetailOpen}
      />
      <CreateExerciseDialog open={createOpen} onOpenChange={setCreateOpen} />
    </>
  );
}
