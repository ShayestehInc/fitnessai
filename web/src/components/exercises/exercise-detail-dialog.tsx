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
import {
  useUpdateExercise,
  useUploadExerciseImage,
  useUploadExerciseVideo,
} from "@/hooks/use-exercises";
import { getErrorMessage } from "@/lib/error-utils";
import { MUSCLE_GROUP_LABELS, DIFFICULTY_LABELS, GOAL_LABELS } from "@/types/program";
import { cn } from "@/lib/utils";
import { FileUploadField } from "./file-upload-field";
import type { Exercise, DifficultyLevel, GoalType } from "@/types/program";

const DIFFICULTY_COLORS: Record<DifficultyLevel, string> = {
  beginner: "bg-emerald-100 text-emerald-700",
  intermediate: "bg-amber-100 text-amber-700",
  advanced: "bg-red-100 text-red-700",
};

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
    difficulty_level: "" as DifficultyLevel | "",
    suitable_for_goals: [] as GoalType[],
  });
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [videoFile, setVideoFile] = useState<File | null>(null);

  useEffect(() => {
    if (exercise && open) {
      setForm({
        name: exercise.name,
        muscle_group: exercise.muscle_group,
        description: exercise.description || "",
        video_url: exercise.video_url || "",
        image_url: exercise.image_url || "",
        difficulty_level: exercise.difficulty_level || "",
        suitable_for_goals: exercise.suitable_for_goals || [],
      });
      setImgError(false);
      setImageFile(null);
      setVideoFile(null);
    }
    if (!open) {
      setEditing(false);
    }
  }, [exercise, open]);

  const updateMutation = useUpdateExercise(exercise?.id ?? 0);
  const uploadImageMutation = useUploadExerciseImage(exercise?.id ?? 0);
  const uploadVideoMutation = useUploadExerciseVideo(exercise?.id ?? 0);

  const isSaving =
    updateMutation.isPending ||
    uploadImageMutation.isPending ||
    uploadVideoMutation.isPending;

  const handleSave = useCallback(async () => {
    if (!form.name.trim()) {
      toast.error("Name is required");
      return;
    }
    if (!form.muscle_group) {
      toast.error("Muscle group is required");
      return;
    }

    try {
      // 1. Upload files first if selected
      if (imageFile) {
        await uploadImageMutation.mutateAsync(imageFile);
      }
      if (videoFile) {
        await uploadVideoMutation.mutateAsync(videoFile);
      }

      // 2. PATCH other fields (only include URL fields if no file was uploaded)
      const patchData: Record<string, string | string[] | null | undefined> = {
        name: form.name.trim(),
        muscle_group: form.muscle_group,
        description: form.description.trim() || undefined,
        difficulty_level: form.difficulty_level || null,
        suitable_for_goals: form.suitable_for_goals,
      };
      if (!imageFile) {
        patchData.image_url = form.image_url.trim() || undefined;
      }
      if (!videoFile) {
        patchData.video_url = form.video_url.trim() || undefined;
      }

      await updateMutation.mutateAsync(patchData);

      toast.success("Exercise updated");
      setEditing(false);
      setImageFile(null);
      setVideoFile(null);
    } catch (err) {
      toast.error(getErrorMessage(err));
    }
  }, [
    form,
    imageFile,
    videoFile,
    updateMutation,
    uploadImageMutation,
    uploadVideoMutation,
  ]);

  if (!exercise) return null;

  const ytId = exercise.video_url ? extractYouTubeId(exercise.video_url) : null;
  const displayImageUrl = editing ? form.image_url : exercise.image_url;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <div className="flex items-start justify-between gap-2">
            <div>
              <DialogTitle>{editing ? "Edit Exercise" : exercise.name}</DialogTitle>
              <DialogDescription asChild>
                {!editing ? (
                  <div className="flex flex-wrap items-center gap-1.5 pt-1">
                    <Badge variant="secondary">
                      {MUSCLE_GROUP_LABELS[exercise.muscle_group] ??
                        exercise.muscle_group}
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
                ) : (
                  <span />
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
              <Label htmlFor="edit-difficulty">Difficulty Level</Label>
              <select
                id="edit-difficulty"
                value={form.difficulty_level}
                onChange={(e) =>
                  setForm((f) => ({
                    ...f,
                    difficulty_level: e.target.value as DifficultyLevel | "",
                  }))
                }
                className="h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm"
              >
                <option value="">No difficulty set</option>
                {Object.entries(DIFFICULTY_LABELS).map(([key, label]) => (
                  <option key={key} value={key}>
                    {label}
                  </option>
                ))}
              </select>
            </div>

            <div className="space-y-2">
              <Label>Training Goals</Label>
              <div className="flex flex-wrap gap-2">
                {Object.entries(GOAL_LABELS).map(([key, label]) => {
                  const goalKey = key as GoalType;
                  const isSelected = form.suitable_for_goals.includes(goalKey);
                  return (
                    <button
                      key={key}
                      type="button"
                      onClick={() =>
                        setForm((f) => ({
                          ...f,
                          suitable_for_goals: isSelected
                            ? f.suitable_for_goals.filter((g) => g !== goalKey)
                            : [...f.suitable_for_goals, goalKey],
                        }))
                      }
                      className={cn(
                        "inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-medium transition-colors",
                        isSelected
                          ? "border-primary bg-primary text-primary-foreground"
                          : "border-input text-muted-foreground hover:bg-accent",
                      )}
                    >
                      {label}
                    </button>
                  );
                })}
              </div>
            </div>

            <FileUploadField
              label="Image"
              accept="image/jpeg,image/png,image/gif,image/webp"
              maxSizeMB={10}
              currentUrl={form.image_url}
              onFileSelect={setImageFile}
              onUrlChange={(url) => setForm((f) => ({ ...f, image_url: url }))}
              uploading={uploadImageMutation.isPending}
              selectedFile={imageFile}
            />

            <FileUploadField
              label="Video"
              accept="video/mp4,video/quicktime,video/x-msvideo,video/webm,video/x-m4v"
              maxSizeMB={100}
              currentUrl={form.video_url}
              onFileSelect={setVideoFile}
              onUrlChange={(url) => setForm((f) => ({ ...f, video_url: url }))}
              uploading={uploadVideoMutation.isPending}
              selectedFile={videoFile}
            />
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

            {exercise.suitable_for_goals?.length > 0 && (
              <div className="space-y-1.5">
                <p className="text-xs font-medium text-muted-foreground">Suitable For</p>
                <div className="flex flex-wrap gap-1.5">
                  {exercise.suitable_for_goals.map((goal: GoalType) => (
                    <span
                      key={goal}
                      className="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs text-muted-foreground"
                    >
                      {GOAL_LABELS[goal] ?? goal}
                    </span>
                  ))}
                </div>
              </div>
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
              disabled={isSaving}
            >
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={isSaving}>
              {isSaving && (
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
