"use client";

import { useState, useMemo } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ArrowRight, ImageIcon, ArrowDown, ArrowUp } from "lucide-react";
import type { ProgressPhoto } from "@/types/progress";

interface ComparisonViewProps {
  photos: ProgressPhoto[];
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const MEASUREMENT_LABELS: Record<string, string> = {
  waist: "Waist",
  chest: "Chest",
  arms: "Arms",
  hips: "Hips",
  thighs: "Thighs",
};

export function ComparisonView({
  photos,
  open,
  onOpenChange,
}: ComparisonViewProps) {
  const [photo1Id, setPhoto1Id] = useState<number | null>(null);
  const [photo2Id, setPhoto2Id] = useState<number | null>(null);

  function handleOpenChange(nextOpen: boolean) {
    if (!nextOpen) {
      setPhoto1Id(null);
      setPhoto2Id(null);
    }
    onOpenChange(nextOpen);
  }

  const photo1 = useMemo(
    () => photos.find((p) => p.id === photo1Id) ?? null,
    [photos, photo1Id],
  );
  const photo2 = useMemo(
    () => photos.find((p) => p.id === photo2Id) ?? null,
    [photos, photo2Id],
  );

  // Compute measurement diffs.
  const diffs = useMemo(() => {
    if (!photo1 || !photo2) return [];
    const allKeys = new Set([
      ...Object.keys(photo1.measurements),
      ...Object.keys(photo2.measurements),
    ]);
    return Array.from(allKeys).map((key) => {
      const v1 = photo1.measurements[key] ?? 0;
      const v2 = photo2.measurements[key] ?? 0;
      const diff = v2 - v1;
      return { key, v1, v2, diff };
    });
  }, [photo1, photo2]);

  if (photos.length < 2) {
    return (
      <Dialog open={open} onOpenChange={handleOpenChange}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Compare Photos</DialogTitle>
            <DialogDescription>
              You need at least 2 progress photos to compare.
            </DialogDescription>
          </DialogHeader>
          <div className="flex flex-col items-center py-8 text-center">
            <ImageIcon className="mb-4 h-12 w-12 text-muted-foreground" />
            <p className="text-sm text-muted-foreground">
              Take at least 2 progress photos to use comparison.
            </p>
          </div>
        </DialogContent>
      </Dialog>
    );
  }

  function formatDate(dateStr: string): string {
    return new Date(dateStr).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="max-w-3xl max-h-[90dvh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Compare Progress</DialogTitle>
          <DialogDescription>
            Select two photos to compare side by side.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Photo selectors */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-2 block text-sm font-medium">Before</label>
              <select
                value={photo1Id ?? ""}
                onChange={(e) => setPhoto1Id(e.target.value ? Number(e.target.value) : null)}
                className="w-full rounded-md border bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                aria-label="Select before photo"
              >
                <option value="">Select a photo</option>
                {photos.map((p) => (
                  <option key={p.id} value={p.id} disabled={p.id === photo2Id}>
                    {formatDate(p.date)} — {p.category}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium">After</label>
              <select
                value={photo2Id ?? ""}
                onChange={(e) => setPhoto2Id(e.target.value ? Number(e.target.value) : null)}
                className="w-full rounded-md border bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                aria-label="Select after photo"
              >
                <option value="">Select a photo</option>
                {photos.map((p) => (
                  <option key={p.id} value={p.id} disabled={p.id === photo1Id}>
                    {formatDate(p.date)} — {p.category}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Side-by-side comparison */}
          {photo1 && photo2 ? (
            <>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <div className="relative aspect-[3/4] overflow-hidden rounded-lg bg-muted">
                    {photo1.photo_url ? (
                      <img
                        src={photo1.photo_url}
                        alt={`Before — ${formatDate(photo1.date)}`}
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center">
                        <ImageIcon className="h-8 w-8 text-muted-foreground" />
                      </div>
                    )}
                  </div>
                  <div className="text-center text-sm text-muted-foreground">
                    {formatDate(photo1.date)}
                    <Badge variant="secondary" className="ml-2 capitalize">
                      {photo1.category}
                    </Badge>
                  </div>
                </div>
                <div className="space-y-2">
                  <div className="relative aspect-[3/4] overflow-hidden rounded-lg bg-muted">
                    {photo2.photo_url ? (
                      <img
                        src={photo2.photo_url}
                        alt={`After — ${formatDate(photo2.date)}`}
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center">
                        <ImageIcon className="h-8 w-8 text-muted-foreground" />
                      </div>
                    )}
                  </div>
                  <div className="text-center text-sm text-muted-foreground">
                    {formatDate(photo2.date)}
                    <Badge variant="secondary" className="ml-2 capitalize">
                      {photo2.category}
                    </Badge>
                  </div>
                </div>
              </div>

              {/* Measurement diffs */}
              {diffs.length > 0 && (
                <div className="rounded-lg border p-4" aria-live="polite">
                  <h4 className="mb-3 text-sm font-semibold">
                    Measurement Changes
                  </h4>
                  <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                    {diffs.map(({ key, v1, v2, diff }) => (
                      <div
                        key={key}
                        className="flex items-center justify-between rounded-md bg-muted px-3 py-2"
                      >
                        <span className="text-sm">
                          {MEASUREMENT_LABELS[key] ?? key}
                        </span>
                        <span
                          className={`flex items-center text-sm font-medium ${
                            diff < 0
                              ? "text-green-600"
                              : diff > 0
                                ? "text-amber-600"
                                : "text-muted-foreground"
                          }`}
                        >
                          {diff > 0 && <ArrowUp className="mr-1 h-3 w-3" />}
                          {diff < 0 && <ArrowDown className="mr-1 h-3 w-3" />}
                          {diff > 0 ? "+" : ""}
                          {diff.toFixed(1)} cm
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </>
          ) : (
            <div className="flex items-center justify-center gap-4 py-12 text-muted-foreground" role="status" aria-label="Select two photos above to compare">
              <div className="h-32 w-24 rounded-lg border-2 border-dashed" aria-hidden="true" />
              <ArrowRight className="h-6 w-6" aria-hidden="true" />
              <div className="h-32 w-24 rounded-lg border-2 border-dashed" aria-hidden="true" />
              <span className="sr-only">Select two photos above to see a side-by-side comparison</span>
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
