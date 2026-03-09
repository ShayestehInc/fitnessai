"use client";

import { useState, useRef, useCallback, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Camera, Loader2, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { useUploadProgressPhoto } from "@/hooks/use-progress-photos";
import { toast } from "sonner";
import type { PhotoCategory } from "@/types/progress";

interface UploadDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const CATEGORY_OPTIONS: { label: string; value: Exclude<PhotoCategory, "all"> }[] = [
  { label: "Front", value: "front" },
  { label: "Side", value: "side" },
  { label: "Back", value: "back" },
  { label: "Other", value: "other" },
];

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"];

export function UploadDialog({ open, onOpenChange }: UploadDialogProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [category, setCategory] = useState<Exclude<PhotoCategory, "all">>("front");
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [notes, setNotes] = useState("");
  const [waist, setWaist] = useState("");
  const [chest, setChest] = useState("");
  const [arms, setArms] = useState("");
  const [hips, setHips] = useState("");
  const [thighs, setThighs] = useState("");

  const [dragging, setDragging] = useState(false);
  const uploadMutation = useUploadProgressPhoto();

  // Revoke object URL on unmount to prevent memory leaks.
  useEffect(() => {
    return () => {
      if (preview) URL.revokeObjectURL(preview);
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const processFile = useCallback((selected: File) => {
    if (!ALLOWED_TYPES.includes(selected.type)) {
      toast.error("Only JPEG, PNG, and WebP files are supported");
      return;
    }
    if (selected.size > MAX_FILE_SIZE) {
      toast.error("Photo must be under 10MB");
      return;
    }
    setFile(selected);
    const url = URL.createObjectURL(selected);
    setPreview(url);
  }, []);

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    setDragging(false);
    const dropped = e.dataTransfer.files[0];
    if (dropped) processFile(dropped);
  }

  function handleDragOver(e: React.DragEvent) {
    e.preventDefault();
    setDragging(true);
  }

  function handleDragLeave(e: React.DragEvent) {
    e.preventDefault();
    setDragging(false);
  }

  function resetForm() {
    setFile(null);
    setPreview(null);
    setCategory("front");
    setDate(new Date().toISOString().split("T")[0]);
    setNotes("");
    setWaist("");
    setChest("");
    setArms("");
    setHips("");
    setThighs("");
  }

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const selected = e.target.files?.[0];
    if (!selected) return;
    processFile(selected);
  }

  function removeFile() {
    setFile(null);
    if (preview) URL.revokeObjectURL(preview);
    setPreview(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!file) return;

    const formData = new FormData();
    formData.append("photo", file);
    formData.append("category", category);
    formData.append("date", date);
    if (notes.trim()) formData.append("notes", notes.trim());

    const measurements: Record<string, number> = {};
    if (waist) measurements.waist = parseFloat(waist);
    if (chest) measurements.chest = parseFloat(chest);
    if (arms) measurements.arms = parseFloat(arms);
    if (hips) measurements.hips = parseFloat(hips);
    if (thighs) measurements.thighs = parseFloat(thighs);

    if (Object.keys(measurements).length > 0) {
      formData.append("measurements", JSON.stringify(measurements));
    }

    uploadMutation.mutate(formData, {
      onSuccess: () => {
        toast.success("Progress photo saved!");
        resetForm();
        onOpenChange(false);
      },
      onError: () => {
        toast.error("Failed to upload photo. Please try again.");
      },
    });
  }

  return (
    <Dialog open={open} onOpenChange={(v) => { onOpenChange(v); if (!v) resetForm(); }}>
      <DialogContent className="max-w-md max-h-[90dvh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Add Progress Photo</DialogTitle>
          <DialogDescription>
            Upload a photo and optionally add body measurements.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* File picker */}
          <div>
            <Label>Photo</Label>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              onChange={handleFileChange}
              className="hidden"
              aria-label="Select progress photo"
            />
            {preview ? (
              <div className="relative mt-2 aspect-[3/4] w-full max-w-[200px] overflow-hidden rounded-lg bg-muted">
                <img src={preview} alt="Preview" className="h-full w-full object-cover" />
                <button
                  type="button"
                  onClick={removeFile}
                  className="absolute right-1 top-1 rounded-full bg-black/60 p-1 text-white hover:bg-black/80"
                  aria-label="Remove photo"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                onDrop={handleDrop}
                onDragOver={handleDragOver}
                onDragLeave={handleDragLeave}
                className={cn(
                  "mt-2 flex w-full items-center justify-center gap-2 rounded-lg border-2 border-dashed py-8 text-muted-foreground transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
                  dragging
                    ? "border-primary bg-primary/5"
                    : "border-muted-foreground/25 hover:border-muted-foreground/50",
                )}
              >
                <Camera className="h-5 w-5" />
                <span className="text-sm">
                  {dragging ? "Drop photo here" : "Click or drag a photo here"}
                </span>
              </button>
            )}
          </div>

          {/* Category */}
          <div>
            <Label>Category</Label>
            <div className="mt-2 grid grid-cols-4 gap-2" role="radiogroup" aria-label="Photo category">
              {CATEGORY_OPTIONS.map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  role="radio"
                  aria-checked={category === opt.value}
                  onClick={() => setCategory(opt.value)}
                  className={cn(
                    "rounded-lg border py-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
                    category === opt.value
                      ? "border-primary bg-primary/10 text-primary"
                      : "border-border text-muted-foreground hover:bg-muted",
                  )}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Date */}
          <div>
            <Label htmlFor="photo-date">Date</Label>
            <Input
              id="photo-date"
              type="date"
              value={date}
              max={new Date().toISOString().split("T")[0]}
              onChange={(e) => setDate(e.target.value)}
              className="mt-1"
            />
          </div>

          {/* Measurements */}
          <div>
            <Label>Body Measurements (cm) — Optional</Label>
            <div className="mt-2 grid grid-cols-2 gap-2">
              {[
                { label: "Waist", value: waist, setter: setWaist },
                { label: "Chest", value: chest, setter: setChest },
                { label: "Arms", value: arms, setter: setArms },
                { label: "Hips", value: hips, setter: setHips },
                { label: "Thighs", value: thighs, setter: setThighs },
              ].map(({ label, value, setter }) => (
                <div key={label}>
                  <Input
                    type="number"
                    placeholder={label}
                    min="0"
                    max="300"
                    step="0.1"
                    value={value}
                    onChange={(e) => setter(e.target.value)}
                    aria-label={`${label} measurement in cm`}
                  />
                </div>
              ))}
            </div>
          </div>

          {/* Notes */}
          <div>
            <Label htmlFor="photo-notes">Notes (optional)</Label>
            <Textarea
              id="photo-notes"
              placeholder="Any observations about your progress..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              maxLength={500}
              className="mt-1"
            />
          </div>

          <Button
            type="submit"
            disabled={!file || uploadMutation.isPending}
            className="w-full"
          >
            {uploadMutation.isPending && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            )}
            Save Photo
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}
