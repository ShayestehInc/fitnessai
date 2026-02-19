"use client";

import { useState } from "react";
import { Dumbbell } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { MUSCLE_GROUP_LABELS } from "@/types/program";
import type { Exercise } from "@/types/program";

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
        "flex flex-col items-start gap-3 rounded-lg border p-4 text-left transition-all",
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
      <Badge variant="secondary">
        {MUSCLE_GROUP_LABELS[exercise.muscle_group] ?? exercise.muscle_group}
      </Badge>
    </button>
  );
}
