"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Trash2, Loader2 } from "lucide-react";
import { useDeleteProgressPhoto } from "@/hooks/use-progress-photos";
import { toast } from "sonner";
import type { ProgressPhoto } from "@/types/progress";

interface PhotoDetailDialogProps {
  photo: ProgressPhoto | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  readOnly?: boolean;
}

const MEASUREMENT_LABELS: Record<string, string> = {
  waist: "Waist",
  chest: "Chest",
  arms: "Arms",
  hips: "Hips",
  thighs: "Thighs",
};

export function PhotoDetailDialog({
  photo,
  open,
  onOpenChange,
  readOnly = false,
}: PhotoDetailDialogProps) {
  const [confirmingDelete, setConfirmingDelete] = useState(false);
  const deleteMutation = useDeleteProgressPhoto();

  if (!photo) return null;

  const measurements = Object.entries(photo.measurements);
  const formattedDate = new Date(photo.date).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  function handleDelete() {
    if (!photo) return;
    if (!confirmingDelete) {
      setConfirmingDelete(true);
      return;
    }
    deleteMutation.mutate(photo.id, {
      onSuccess: () => {
        toast.success("Photo deleted");
        onOpenChange(false);
        setConfirmingDelete(false);
      },
      onError: () => {
        toast.error("Failed to delete photo");
        setConfirmingDelete(false);
      },
    });
  }

  return (
    <Dialog open={open} onOpenChange={(v) => { onOpenChange(v); setConfirmingDelete(false); }}>
      <DialogContent className="max-w-lg p-0 overflow-hidden max-h-[90dvh] overflow-y-auto">
        <DialogHeader className="sr-only">
          <DialogTitle>Progress Photo — {formattedDate}</DialogTitle>
          <DialogDescription>
            {photo.category} view progress photo details
          </DialogDescription>
        </DialogHeader>

        {/* Photo */}
        {photo.photo_url && (
          <div className="relative aspect-[3/4] w-full bg-muted">
            <img
              src={photo.photo_url}
              alt={`${photo.category} progress photo from ${formattedDate}`}
              className="h-full w-full object-cover"
            />
          </div>
        )}

        {/* Details */}
        <div className="space-y-4 p-6">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-muted-foreground">
              {formattedDate}
            </span>
            <Badge variant="secondary" className="capitalize">
              {photo.category}
            </Badge>
          </div>

          {photo.notes && (
            <p className="text-sm text-foreground">{photo.notes}</p>
          )}

          {measurements.length > 0 && (
            <div>
              <h4 className="mb-2 text-sm font-semibold">Measurements</h4>
              <div className="grid grid-cols-3 gap-3">
                {measurements.map(([key, value]) => (
                  <div
                    key={key}
                    className="rounded-lg bg-muted p-2 text-center"
                  >
                    <p className="text-lg font-semibold">{value}</p>
                    <p className="text-xs text-muted-foreground">
                      {MEASUREMENT_LABELS[key] ?? key} (cm)
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {!readOnly && (
            <Button
              variant={confirmingDelete ? "destructive" : "outline"}
              size="sm"
              onClick={handleDelete}
              disabled={deleteMutation.isPending}
              className="w-full"
            >
              {deleteMutation.isPending ? (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              ) : (
                <Trash2 className="mr-2 h-4 w-4" />
              )}
              {confirmingDelete ? "Confirm Delete" : "Delete Photo"}
            </Button>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
