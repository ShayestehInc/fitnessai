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
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import { getErrorMessage } from "@/lib/error-utils";
import { MUSCLE_GROUP_LABELS } from "@/types/program";
import { FileUploadField } from "./file-upload-field";

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
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);

  const createMutation = useCreateExercise();

  const resetForm = useCallback(() => {
    setName("");
    setMuscleGroup("");
    setDescription("");
    setVideoUrl("");
    setImageUrl("");
    setImageFile(null);
    setVideoFile(null);
    setErrors({});
    setSaving(false);
  }, []);

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      const newErrors: Record<string, string> = {};

      if (!name.trim()) newErrors.name = "Name is required";
      if (!muscleGroup) newErrors.muscle_group = "Muscle group is required";

      if (Object.keys(newErrors).length > 0) {
        setErrors(newErrors);
        return;
      }

      setSaving(true);

      try {
        // 1. Create the exercise (include URLs only if no file was selected)
        const created = await createMutation.mutateAsync({
          name: name.trim(),
          muscle_group: muscleGroup,
          description: description.trim() || undefined,
          image_url: !imageFile ? imageUrl.trim() || undefined : undefined,
          video_url: !videoFile ? videoUrl.trim() || undefined : undefined,
        });

        // 2. Upload files to the newly created exercise
        if (imageFile) {
          const imgFormData = new FormData();
          imgFormData.append("image", imageFile);
          await apiClient.postFormData(
            `${API_URLS.EXERCISES}${created.id}/upload-image/`,
            imgFormData,
          );
        }

        if (videoFile) {
          const vidFormData = new FormData();
          vidFormData.append("video", videoFile);
          await apiClient.postFormData(
            `${API_URLS.EXERCISES}${created.id}/upload-video/`,
            vidFormData,
          );
        }

        toast.success(`Exercise '${created.name}' created`);
        onOpenChange(false);
        resetForm();
      } catch (err) {
        toast.error(getErrorMessage(err));
      } finally {
        setSaving(false);
      }
    },
    [
      name,
      muscleGroup,
      description,
      videoUrl,
      imageUrl,
      imageFile,
      videoFile,
      createMutation,
      onOpenChange,
      resetForm,
    ],
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
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

          <FileUploadField
            label="Image (optional)"
            accept="image/jpeg,image/png,image/gif,image/webp"
            maxSizeMB={10}
            currentUrl={imageUrl}
            onFileSelect={setImageFile}
            onUrlChange={setImageUrl}
            uploading={saving && imageFile !== null}
            selectedFile={imageFile}
          />

          <FileUploadField
            label="Video (optional)"
            accept="video/mp4,video/quicktime,video/x-msvideo,video/webm,video/x-m4v"
            maxSizeMB={100}
            currentUrl={videoUrl}
            onFileSelect={setVideoFile}
            onUrlChange={setVideoUrl}
            uploading={saving && videoFile !== null}
            selectedFile={videoFile}
          />

          <DialogFooter>
            <Button
              variant="outline"
              type="button"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={saving}>
              {saving && (
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
