"use client";

import { Copy, Pencil, Trash2, Star } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import type { MacroPreset } from "@/types/trainer";

interface PresetCardProps {
  preset: MacroPreset;
  onEdit: (preset: MacroPreset) => void;
  onDelete: (preset: MacroPreset) => void;
  onCopy: (preset: MacroPreset) => void;
}

export function PresetCard({
  preset,
  onEdit,
  onDelete,
  onCopy,
}: PresetCardProps) {
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
            <Star className="h-3.5 w-3.5 shrink-0 fill-amber-400 text-amber-400" aria-hidden="true" />
          )}
          {preset.is_default && (
            <span className="sr-only">(Default preset)</span>
          )}
        </div>
        <div className="flex shrink-0 items-center gap-1">
          <button
            type="button"
            onClick={() => onCopy(preset)}
            className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-1 transition-colors"
            aria-label={`Copy ${preset.name} preset to another trainee`}
          >
            <Copy className="h-3.5 w-3.5" />
          </button>
          <button
            type="button"
            onClick={() => onEdit(preset)}
            className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-1 transition-colors"
            aria-label={`Edit ${preset.name} preset`}
          >
            <Pencil className="h-3.5 w-3.5" />
          </button>
          <button
            type="button"
            onClick={() => onDelete(preset)}
            className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-destructive focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive focus-visible:ring-offset-1 transition-colors"
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
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="text-sm font-semibold">
        {value}
        <span className="text-xs font-normal text-muted-foreground">
          {" "}
          {unit}
        </span>
      </p>
    </div>
  );
}
