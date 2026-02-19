"use client";

import { useState } from "react";
import { Dumbbell, ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { MUSCLE_GROUP_LABELS } from "@/types/program";
import type { Exercise } from "@/types/program";

interface ExerciseDetailDialogProps {
  exercise: Exercise | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

function extractYouTubeId(url: string): string | null {
  const match = url.match(
    /(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/,
  );
  return match ? match[1] : null;
}

export function ExerciseDetailDialog({
  exercise,
  open,
  onOpenChange,
}: ExerciseDetailDialogProps) {
  const [imgError, setImgError] = useState(false);

  if (!exercise) return null;

  const ytId = exercise.video_url ? extractYouTubeId(exercise.video_url) : null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{exercise.name}</DialogTitle>
          <DialogDescription>
            <Badge variant="secondary">
              {MUSCLE_GROUP_LABELS[exercise.muscle_group] ??
                exercise.muscle_group}
            </Badge>
          </DialogDescription>
        </DialogHeader>

        {exercise.image_url && !imgError ? (
          <img
            src={exercise.image_url}
            alt={exercise.name}
            className="h-48 w-full rounded-lg object-cover"
            onError={() => setImgError(true)}
          />
        ) : (
          <div className="flex h-48 w-full items-center justify-center rounded-lg bg-muted">
            <Dumbbell className="h-16 w-16 text-muted-foreground" />
          </div>
        )}

        {exercise.description && (
          <p className="text-sm text-muted-foreground">{exercise.description}</p>
        )}

        {ytId && (
          <a
            href={exercise.video_url!}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 rounded-lg border p-3 transition-colors hover:bg-accent"
          >
            <img
              src={`https://img.youtube.com/vi/${ytId}/hqdefault.jpg`}
              alt="Video thumbnail"
              className="h-16 w-24 rounded object-cover"
            />
            <div className="flex items-center gap-1 text-sm font-medium text-primary">
              <ExternalLink className="h-4 w-4" />
              Watch Video
            </div>
          </a>
        )}
      </DialogContent>
    </Dialog>
  );
}
