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
import { useCreateFeatureRequest } from "@/hooks/use-feature-requests";
import { getErrorMessage } from "@/lib/error-utils";
import {
  CATEGORY_LABELS,
  type FeatureRequestCategory,
} from "@/types/feature-request";

interface CreateFeatureRequestDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function CreateFeatureRequestDialog({
  open,
  onOpenChange,
}: CreateFeatureRequestDialogProps) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState<FeatureRequestCategory | "">("");
  const [errors, setErrors] = useState<Record<string, string>>({});

  const createMutation = useCreateFeatureRequest();

  const resetForm = useCallback(() => {
    setTitle("");
    setDescription("");
    setCategory("");
    setErrors({});
  }, []);

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const newErrors: Record<string, string> = {};

      if (title.trim().length < 10) {
        newErrors.title = "Title must be at least 10 characters";
      }
      if (description.trim().length < 30) {
        newErrors.description = "Description must be at least 30 characters";
      }
      if (!category) {
        newErrors.category = "Category is required";
      }

      if (Object.keys(newErrors).length > 0) {
        setErrors(newErrors);
        return;
      }

      createMutation.mutate(
        {
          title: title.trim(),
          description: description.trim(),
          category: category as FeatureRequestCategory,
        },
        {
          onSuccess: () => {
            toast.success("Feature request submitted");
            onOpenChange(false);
            resetForm();
          },
          onError: (err) => toast.error(getErrorMessage(err)),
        },
      );
    },
    [title, description, category, createMutation, onOpenChange, resetForm],
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Submit Feature Request</DialogTitle>
          <DialogDescription>
            Describe the feature you would like to see.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <div className="flex justify-between">
              <Label htmlFor="fr-title">Title</Label>
              <span className="text-xs text-muted-foreground">
                {title.length}/200
              </span>
            </div>
            <Input
              id="fr-title"
              value={title}
              onChange={(e) => {
                setTitle(e.target.value);
                setErrors((prev) => ({ ...prev, title: "" }));
              }}
              maxLength={200}
              placeholder="Feature title (min 10 characters)"
              aria-invalid={Boolean(errors.title)}
            />
            {errors.title && (
              <p className="text-sm text-destructive">{errors.title}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="fr-category">Category</Label>
            <select
              id="fr-category"
              value={category}
              onChange={(e) => {
                setCategory(e.target.value as FeatureRequestCategory | "");
                setErrors((prev) => ({ ...prev, category: "" }));
              }}
              className="h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm"
              aria-invalid={Boolean(errors.category)}
            >
              <option value="">Select a category</option>
              {Object.entries(CATEGORY_LABELS).map(([key, label]) => (
                <option key={key} value={key}>
                  {label}
                </option>
              ))}
            </select>
            {errors.category && (
              <p className="text-sm text-destructive">{errors.category}</p>
            )}
          </div>

          <div className="space-y-2">
            <div className="flex justify-between">
              <Label htmlFor="fr-desc">Description</Label>
              <span className="text-xs text-muted-foreground">
                {description.length}/2000
              </span>
            </div>
            <textarea
              id="fr-desc"
              value={description}
              onChange={(e) => {
                setDescription(e.target.value);
                setErrors((prev) => ({ ...prev, description: "" }));
              }}
              maxLength={2000}
              rows={5}
              placeholder="Describe the feature in detail (min 30 characters)..."
              className="w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
              aria-invalid={Boolean(errors.description)}
            />
            {errors.description && (
              <p className="text-sm text-destructive">{errors.description}</p>
            )}
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
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              Submit
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
