"use client";

import { useState } from "react";
import {
  Plus,
  Utensils,
  RefreshCw,
  Loader2,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useMacroPresets, useDeleteMacroPreset } from "@/hooks/use-macro-presets";
import { getErrorMessage } from "@/lib/error-utils";
import { PresetFormPanel } from "./preset-form-panel";
import { CopyPresetPanel } from "./copy-preset-panel";
import { PresetCard } from "./preset-card";
import type { MacroPreset } from "@/types/trainer";
import { useLocale } from "@/providers/locale-provider";

interface MacroPresetsSectionProps {
  traineeId: number;
  traineeName: string;
}

export function MacroPresetsSection({
  traineeId,
  traineeName,
}: MacroPresetsSectionProps) {
  const { t } = useLocale();
  const { data: presets, isLoading, isError, refetch } = useMacroPresets(traineeId);
  const deleteMutation = useDeleteMacroPreset(traineeId);

  const [formOpen, setFormOpen] = useState(false);
  const [editingPreset, setEditingPreset] = useState<MacroPreset | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<MacroPreset | null>(null);
  const [copyTarget, setCopyTarget] = useState<MacroPreset | null>(null);

  const handleEdit = (preset: MacroPreset) => {
    setEditingPreset(preset);
    setFormOpen(true);
  };

  const handleCreate = () => {
    setEditingPreset(null);
    setFormOpen(true);
  };

  const handleDeleteConfirm = () => {
    if (!deleteTarget) return;
    deleteMutation.mutate(deleteTarget.id, {
      onSuccess: () => {
        toast.success(t("trainees.presetDeleted"));
        setDeleteTarget(null);
      },
      onError: (err) => toast.error(getErrorMessage(err)),
    });
  };

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>{t("trainees.macroPresets")}</CardTitle>
              <CardDescription>
                Nutrition templates for this trainee
              </CardDescription>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={handleCreate}
              aria-label="Add macro preset"
            >
              <Plus className="mr-2 h-4 w-4" />
              Add Preset
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading && (
            <div aria-busy="true" aria-label="Loading macro presets">
              <PresetsSkeleton />
            </div>
          )}

          {isError && (
            <div
              className="flex flex-col items-center gap-2 py-6 text-center"
              role="alert"
            >
              <p className="text-sm text-muted-foreground">
                Failed to load macro presets.
              </p>
              <Button
                variant="outline"
                size="sm"
                onClick={() => refetch()}
                aria-label="Retry loading macro presets"
              >
                <RefreshCw className="mr-2 h-4 w-4" />
                Retry
              </Button>
            </div>
          )}

          {!isLoading && !isError && presets && presets.length === 0 && (
            <div className="flex flex-col items-center gap-3 py-8 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-muted">
                <Utensils className="h-6 w-6 text-muted-foreground" />
              </div>
              <div>
                <p className="text-sm font-medium">{t("trainees.noMacroPresets")}</p>
                <p className="text-sm text-muted-foreground">
                  Create presets like Training Day, Rest Day to quickly manage
                  nutrition for this trainee.
                </p>
              </div>
              <Button variant="outline" size="sm" onClick={handleCreate}>
                <Plus className="mr-2 h-4 w-4" />
                Add Preset
              </Button>
            </div>
          )}

          {!isLoading && !isError && presets && presets.length > 0 && (
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {presets.map((preset) => (
                <PresetCard
                  key={preset.id}
                  preset={preset}
                  onEdit={handleEdit}
                  onDelete={setDeleteTarget}
                  onCopy={setCopyTarget}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Create / Edit Panel */}
      <PresetFormPanel
        traineeId={traineeId}
        traineeName={traineeName}
        preset={editingPreset}
        open={formOpen}
        onOpenChange={setFormOpen}
      />

      {/* Copy Panel */}
      <CopyPresetPanel
        traineeId={traineeId}
        preset={copyTarget}
        open={copyTarget !== null}
        onOpenChange={(open) => {
          if (!open) setCopyTarget(null);
        }}
      />

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteTarget !== null}
        onOpenChange={(open) => {
          if (!open && !deleteMutation.isPending) setDeleteTarget(null);
        }}
      >
        <DialogContent
          className="sm:max-w-sm"
          role="alertdialog"
          aria-describedby="delete-preset-description"
          onPointerDownOutside={(e) => {
            if (deleteMutation.isPending) e.preventDefault();
          }}
          onEscapeKeyDown={(e) => {
            if (deleteMutation.isPending) e.preventDefault();
          }}
        >
          <DialogHeader>
            <DialogTitle>{t("trainees.deletePreset")}</DialogTitle>
            <DialogDescription id="delete-preset-description">
              Are you sure you want to delete the preset &ldquo;
              {deleteTarget?.name}&rdquo;? This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setDeleteTarget(null)}
              disabled={deleteMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDeleteConfirm}
              disabled={deleteMutation.isPending}
            >
              {deleteMutation.isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}

function PresetsSkeleton() {
  return (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
      {[1, 2, 3].map((i) => (
        <div key={i} className="rounded-lg border p-4 space-y-3">
          <div className="flex items-center justify-between">
            <Skeleton className="h-4 w-24" />
            <div className="flex gap-1">
              <Skeleton className="h-5 w-5 rounded" />
              <Skeleton className="h-5 w-5 rounded" />
              <Skeleton className="h-5 w-5 rounded" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-2">
            <Skeleton className="h-10 rounded-md" />
            <Skeleton className="h-10 rounded-md" />
            <Skeleton className="h-10 rounded-md" />
            <Skeleton className="h-10 rounded-md" />
          </div>
          <Skeleton className="h-5 w-16 rounded-full" />
        </div>
      ))}
    </div>
  );
}
