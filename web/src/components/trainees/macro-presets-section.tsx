"use client";

import { useState } from "react";
import {
  Plus,
  Pencil,
  Trash2,
  Copy,
  Utensils,
  Star,
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
import { Badge } from "@/components/ui/badge";
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
import { PresetFormDialog } from "./preset-form-dialog";
import { CopyPresetDialog } from "./copy-preset-dialog";
import type { MacroPreset } from "@/types/trainer";

interface MacroPresetsSectionProps {
  traineeId: number;
  traineeName: string;
}

export function MacroPresetsSection({
  traineeId,
  traineeName,
}: MacroPresetsSectionProps) {
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
        toast.success("Preset deleted");
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
              <CardTitle>Macro Presets</CardTitle>
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
          {isLoading && <PresetsSkeleton />}

          {isError && (
            <div className="flex flex-col items-center gap-2 py-6 text-center">
              <p className="text-sm text-muted-foreground">
                Failed to load macro presets.
              </p>
              <Button variant="outline" size="sm" onClick={() => refetch()}>
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
                <p className="text-sm font-medium">No macro presets</p>
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

      {/* Create / Edit Dialog */}
      <PresetFormDialog
        traineeId={traineeId}
        traineeName={traineeName}
        preset={editingPreset}
        open={formOpen}
        onOpenChange={setFormOpen}
      />

      {/* Copy Dialog */}
      <CopyPresetDialog
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
          if (!open) setDeleteTarget(null);
        }}
      >
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Delete Preset</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete the preset &ldquo;
              {deleteTarget?.name}&rdquo;? This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteTarget(null)}>
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

function PresetCard({
  preset,
  onEdit,
  onDelete,
  onCopy,
}: {
  preset: MacroPreset;
  onEdit: (preset: MacroPreset) => void;
  onDelete: (preset: MacroPreset) => void;
  onCopy: (preset: MacroPreset) => void;
}) {
  const frequencyLabel =
    preset.frequency_per_week !== null
      ? preset.frequency_per_week === 7
        ? "Daily"
        : `${preset.frequency_per_week}x/wk`
      : null;

  return (
    <div className="rounded-lg border p-4 space-y-3">
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex items-center gap-2">
          <p
            className="truncate text-sm font-semibold"
            title={preset.name}
          >
            {preset.name}
          </p>
          {preset.is_default && (
            <Star className="h-3.5 w-3.5 shrink-0 fill-amber-400 text-amber-400" aria-label="Default preset" />
          )}
        </div>
        <div className="flex shrink-0 items-center gap-1">
          <button
            type="button"
            onClick={() => onCopy(preset)}
            className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
            aria-label={`Copy ${preset.name} preset to another trainee`}
          >
            <Copy className="h-3.5 w-3.5" />
          </button>
          <button
            type="button"
            onClick={() => onEdit(preset)}
            className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
            aria-label={`Edit ${preset.name} preset`}
          >
            <Pencil className="h-3.5 w-3.5" />
          </button>
          <button
            type="button"
            onClick={() => onDelete(preset)}
            className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-destructive transition-colors"
            aria-label={`Delete ${preset.name} preset`}
          >
            <Trash2 className="h-3.5 w-3.5" />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-2 text-center">
        <MacroCell label="Calories" value={preset.calories} unit="kcal" />
        <MacroCell label="Protein" value={preset.protein} unit="g" />
        <MacroCell label="Carbs" value={preset.carbs} unit="g" />
        <MacroCell label="Fat" value={preset.fat} unit="g" />
      </div>

      {(frequencyLabel || preset.is_default) && (
        <div className="flex flex-wrap gap-1.5">
          {preset.is_default && (
            <Badge variant="secondary" className="text-xs">
              Default
            </Badge>
          )}
          {frequencyLabel && (
            <Badge variant="outline" className="text-xs">
              {frequencyLabel}
            </Badge>
          )}
        </div>
      )}
    </div>
  );
}

function MacroCell({
  label,
  value,
  unit,
}: {
  label: string;
  value: number;
  unit: string;
}) {
  return (
    <div className="rounded-md bg-muted/50 px-2 py-1.5">
      <p className="text-[10px] text-muted-foreground">{label}</p>
      <p className="text-sm font-semibold">
        {value}
        <span className="text-[10px] font-normal text-muted-foreground">
          {" "}
          {unit}
        </span>
      </p>
    </div>
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
