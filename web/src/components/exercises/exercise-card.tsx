"use client";

import { useState } from "react";
import { Dumbbell } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { MUSCLE_GROUP_LABELS, DIFFICULTY_LABELS, GOAL_LABELS } from "@/types/program";
import type { Exercise, DifficultyLevel, GoalType } from "@/types/program";

const DIFFICULTY_COLORS: Record<DifficultyLevel, string> = {
  beginner: "bg-emerald-100 text-emerald-700",
  intermediate: "bg-amber-100 text-amber-700",
  advanced: "bg-red-100 text-red-700",
};

interface ExerciseCardProps {
  exercise: Exercise;
  onClick: () => void;
}

export function ExerciseCard({ exercise, onClick }: ExerciseCardProps) {
  const [imgError, setImgError] = useState(false);

  return (
    <button
      onClick={onClick}
      className={cn(
        "flex flex-col items-start gap-2 rounded-lg border p-4 text-left transition-all",
        "hover:shadow-lg hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
      )}
      aria-label={`View ${exercise.name}`}
    >
      {exercise.image_url && !imgError ? (
        <img
          src={exercise.image_url}
          alt={exercise.name}
          className="h-12 w-16 rounded object-cover"
          onError={() => setImgError(true)}
        />
      ) : (
        <div className="flex h-12 w-16 items-center justify-center rounded bg-muted">
          <Dumbbell className="h-6 w-6 text-muted-foreground" />
        </div>
      )}
      <span className="text-sm font-medium">{exercise.name}</span>
      <div className="flex flex-wrap items-center gap-1.5">
        <Badge variant="secondary">
          {MUSCLE_GROUP_LABELS[exercise.muscle_group] ?? exercise.muscle_group}
        </Badge>
        {exercise.difficulty_level && (
          <span
            className={cn(
              "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium",
              DIFFICULTY_COLORS[exercise.difficulty_level],
            )}
          >
            {DIFFICULTY_LABELS[exercise.difficulty_level]}
          </span>
        )}
      </div>
      {exercise.suitable_for_goals?.length > 0 && (
        <div className="flex flex-wrap gap-1">
          {exercise.suitable_for_goals.slice(0, 3).map((goal: GoalType) => (
            <span
              key={goal}
              className="inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] text-muted-foreground"
            >
              {GOAL_LABELS[goal] ?? goal}
            </span>
          ))}
        </div>
      )}
    </button>
  );
}
