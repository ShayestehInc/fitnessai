"use client";

import { useState, useEffect, useCallback } from "react";
import { Dumbbell, ExternalLink, Pencil, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useUpdateExercise } from "@/hooks/use-exercises";
import { getErrorMessage } from "@/lib/error-utils";
import { MUSCLE_GROUP_LABELS, MuscleGroup } from "@/types/program";
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
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState({
    name: "",
    muscle_group: "",
    description: "",
    video_url: "",
    image_url: "",
  });

  // Reset state when exercise changes or dialog closes
  useEffect(() => {
    if (exercise && open) {
      setForm({
        name: exercise.name,
        muscle_group: exercise.muscle_group,
        description: exercise.description || "",
        video_url: exercise.video_url || "",
        image_url: exercise.image_url || "",
      });
      setImgError(false);
    }
    if (!open) {
      setEditing(false);
    }
  }, [exercise, open]);

  const updateMutation = useUpdateExercise(exercise?.id ?? 0);

  const handleSave = useCallback(() => {
    if (!form.name.trim()) {
      toast.error("Name is required");
      return;
    }
    if (!form.muscle_group) {
      toast.error("Muscle group is required");
      return;
    }

    updateMutation.mutate(
      {
        name: form.name.trim(),
        muscle_group: form.muscle_group,
        description: form.description.trim() || undefined,
        video_url: form.video_url.trim() || undefined,
        image_url: form.image_url.trim() || undefined,
      },
      {
        onSuccess: () => {
          toast.success("Exercise updated");
          setEditing(false);
        },
        onError: (err) => toast.error(getErrorMessage(err)),
      },
    );
  }, [form, updateMutation]);

  if (!exercise) return null;

  const ytId = exercise.video_url ? extractYouTubeId(exercise.video_url) : null;
  const displayImageUrl = editing ? form.image_url : exercise.image_url;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <div className="flex items-start justify-between gap-2">
            <div>
              <DialogTitle>{editing ? "Edit Exercise" : exercise.name}</DialogTitle>
              <DialogDescription>
                {!editing && (
                  <Badge variant="secondary">
                    {MUSCLE_GROUP_LABELS[exercise.muscle_group] ??
                      exercise.muscle_group}
                  </Badge>
                )}
              </DialogDescription>
            </div>
            {!editing && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => setEditing(true)}
              >
                <Pencil className="mr-1.5 h-3.5 w-3.5" />
                Edit
              </Button>
            )}
          </div>
        </DialogHeader>

        {editing ? (
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="edit-name">Name</Label>
              <Input
                id="edit-name"
                value={form.name}
                onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                maxLength={255}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-muscle">Muscle Group</Label>
              <select
                id="edit-muscle"
                value={form.muscle_group}
                onChange={(e) =>
                  setForm((f) => ({ ...f, muscle_group: e.target.value }))
                }
                className="h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm"
              >
                <option value="">Select muscle group</option>
                {Object.entries(MUSCLE_GROUP_LABELS).map(([key, label]) => (
                  <option key={key} value={key}>
                    {label}
                  </option>
                ))}
              </select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-desc">Description</Label>
              <textarea
                id="edit-desc"
                value={form.description}
                onChange={(e) =>
                  setForm((f) => ({ ...f, description: e.target.value }))
                }
                rows={3}
                className="w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-video">Video URL</Label>
              <Input
                id="edit-video"
                value={form.video_url}
                onChange={(e) =>
                  setForm((f) => ({ ...f, video_url: e.target.value }))
                }
                placeholder="https://youtube.com/watch?v=..."
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-image">Image URL</Label>
              <Input
                id="edit-image"
                value={form.image_url}
                onChange={(e) =>
                  setForm((f) => ({ ...f, image_url: e.target.value }))
                }
                placeholder="https://example.com/exercise.jpg"
              />
            </div>
          </div>
        ) : (
          <>
            {displayImageUrl && !imgError ? (
              <img
                src={displayImageUrl}
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
              <p className="text-sm text-muted-foreground">
                {exercise.description}
              </p>
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
          </>
        )}

        {editing && (
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setEditing(false)}
              disabled={updateMutation.isPending}
            >
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={updateMutation.isPending}>
              {updateMutation.isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              Save
            </Button>
          </DialogFooter>
        )}
      </DialogContent>
    </Dialog>
  );
}
