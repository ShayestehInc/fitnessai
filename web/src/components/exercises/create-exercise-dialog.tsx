"use client";

import { useCallback, useState } from "react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
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
import { useCreateExercise } from "@/hooks/use-exercises";
import { getErrorMessage } from "@/lib/error-utils";
import { MUSCLE_GROUP_LABELS, MuscleGroup } from "@/types/program";

interface CreateExerciseDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function CreateExerciseDialog({
  open,
  onOpenChange,
}: CreateExerciseDialogProps) {
  const [name, setName] = useState("");
  const [muscleGroup, setMuscleGroup] = useState("");
  const [description, setDescription] = useState("");
  const [videoUrl, setVideoUrl] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});

  const createMutation = useCreateExercise();

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const newErrors: Record<string, string> = {};

      if (!name.trim()) newErrors.name = "Name is required";
      if (!muscleGroup) newErrors.muscle_group = "Muscle group is required";

      if (Object.keys(newErrors).length > 0) {
        setErrors(newErrors);
        return;
      }

      createMutation.mutate(
        {
          name: name.trim(),
          muscle_group: muscleGroup,
          description: description.trim() || undefined,
          video_url: videoUrl.trim() || undefined,
          image_url: imageUrl.trim() || undefined,
        },
        {
          onSuccess: (data) => {
            toast.success(`Exercise '${data.name}' created`);
            onOpenChange(false);
            setName("");
            setMuscleGroup("");
            setDescription("");
            setVideoUrl("");
            setImageUrl("");
            setErrors({});
          },
          onError: (err) => toast.error(getErrorMessage(err)),
        },
      );
    },
    [name, muscleGroup, description, videoUrl, imageUrl, createMutation, onOpenChange],
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Create Exercise</DialogTitle>
          <DialogDescription>
            Add a new custom exercise to your library.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <div className="flex justify-between">
              <Label htmlFor="ex-name">Name</Label>
              <span className="text-xs text-muted-foreground">
                {name.length}/100
              </span>
            </div>
            <Input
              id="ex-name"
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                setErrors((prev) => ({ ...prev, name: "" }));
              }}
              maxLength={100}
              placeholder="Exercise name"
              aria-invalid={Boolean(errors.name)}
            />
            {errors.name && (
              <p className="text-sm text-destructive">{errors.name}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="ex-muscle">Muscle Group</Label>
            <select
              id="ex-muscle"
              value={muscleGroup}
              onChange={(e) => {
                setMuscleGroup(e.target.value);
                setErrors((prev) => ({ ...prev, muscle_group: "" }));
              }}
              className="h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm"
              aria-invalid={Boolean(errors.muscle_group)}
            >
              <option value="">Select muscle group</option>
              {Object.entries(MUSCLE_GROUP_LABELS).map(([key, label]) => (
                <option key={key} value={key}>
                  {label}
                </option>
              ))}
            </select>
            {errors.muscle_group && (
              <p className="text-sm text-destructive">{errors.muscle_group}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="ex-desc">Description (optional)</Label>
            <textarea
              id="ex-desc"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              maxLength={500}
              rows={3}
              placeholder="Exercise description"
              className="w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="ex-video">Video URL (optional)</Label>
            <Input
              id="ex-video"
              value={videoUrl}
              onChange={(e) => setVideoUrl(e.target.value)}
              placeholder="https://youtube.com/watch?v=..."
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="ex-image">Image URL (optional)</Label>
            <Input
              id="ex-image"
              value={imageUrl}
              onChange={(e) => setImageUrl(e.target.value)}
              placeholder="https://example.com/exercise.jpg"
            />
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              type="button"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={createMutation.isPending}>
              {createMutation.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
              )}
              Create
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
