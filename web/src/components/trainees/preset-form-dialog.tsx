"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { AlertTriangle, Loader2 } from "lucide-react";
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
import {
  useCreateMacroPreset,
  useUpdateMacroPreset,
} from "@/hooks/use-macro-presets";
import { getErrorMessage } from "@/lib/error-utils";
import type { MacroPreset } from "@/types/trainer";

const FREQUENCY_OPTIONS = [
  { value: "", label: "None" },
  { value: "1", label: "1x / week" },
  { value: "2", label: "2x / week" },
  { value: "3", label: "3x / week" },
  { value: "4", label: "4x / week" },
  { value: "5", label: "5x / week" },
  { value: "6", label: "6x / week" },
  { value: "7", label: "Daily" },
] as const;

/** Compute expected calories from macros: protein*4 + carbs*4 + fat*9 */
function computedCalories(proteinStr: string, carbsStr: string, fatStr: string): number | null {
  const p = Number(proteinStr);
  const c = Number(carbsStr);
  const f = Number(fatStr);
  if ([proteinStr, carbsStr, fatStr].some((v) => v === "") || isNaN(p) || isNaN(c) || isNaN(f)) {
    return null;
  }
  return Math.round(p * 4 + c * 4 + f * 9);
}

interface PresetFormDialogProps {
  traineeId: number;
  traineeName: string;
  preset: MacroPreset | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function PresetFormDialog({
  traineeId,
  traineeName,
  preset,
  open,
  onOpenChange,
}: PresetFormDialogProps) {
  const isEdit = preset !== null;

  const [name, setName] = useState("");
  const [calories, setCalories] = useState("");
  const [protein, setProtein] = useState("");
  const [carbs, setCarbs] = useState("");
  const [fat, setFat] = useState("");
  const [frequency, setFrequency] = useState("");
  const [isDefault, setIsDefault] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const createMutation = useCreateMacroPreset(traineeId);
  const updateMutation = useUpdateMacroPreset(traineeId);
  const isPending = createMutation.isPending || updateMutation.isPending;

  // Calorie sanity check: warn if entered calories differ from macro-computed calories by >10%
  const calorieMismatchWarning = useMemo(() => {
    const entered = Number(calories);
    if (!calories || isNaN(entered)) return null;
    const computed = computedCalories(protein, carbs, fat);
    if (computed === null || computed === 0) return null;
    const diff = Math.abs(entered - computed);
    const pct = diff / computed;
    if (pct > 0.1) {
      return `Macros add up to ~${computed} kcal (P\u00d74 + C\u00d74 + F\u00d79). You entered ${Math.round(entered)} kcal.`;
    }
    return null;
  }, [calories, protein, carbs, fat]);

  useEffect(() => {
    if (open) {
      if (preset) {
        setName(preset.name);
        setCalories(String(preset.calories));
        setProtein(String(preset.protein));
        setCarbs(String(preset.carbs));
        setFat(String(preset.fat));
        setFrequency(
          preset.frequency_per_week !== null
            ? String(preset.frequency_per_week)
            : "",
        );
        setIsDefault(preset.is_default);
      } else {
        setName("");
        setCalories("");
        setProtein("");
        setCarbs("");
        setFat("");
        setFrequency("");
        setIsDefault(false);
      }
      setErrors({});
    }
  }, [open, preset]);

  const validate = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};

    if (!name.trim()) {
      newErrors.name = "Name is required";
    } else if (name.trim().length > 100) {
      newErrors.name = "Name must be 100 characters or less";
    }

    // Round before validating so decimal edge cases (e.g. 499.6 -> 500) pass correctly
    const calRaw = Number(calories);
    const cal = Math.round(calRaw);
    if (!calories || isNaN(calRaw) || cal < 500 || cal > 10000) {
      newErrors.calories = "Enter a value between 500 and 10,000";
    }

    const proRaw = Number(protein);
    const pro = Math.round(proRaw);
    if (protein === "" || isNaN(proRaw) || pro < 0 || pro > 500) {
      newErrors.protein = "Enter a value between 0 and 500";
    }

    const crbRaw = Number(carbs);
    const crb = Math.round(crbRaw);
    if (carbs === "" || isNaN(crbRaw) || crb < 0 || crb > 1000) {
      newErrors.carbs = "Enter a value between 0 and 1,000";
    }

    const ftRaw = Number(fat);
    const ft = Math.round(ftRaw);
    if (fat === "" || isNaN(ftRaw) || ft < 0 || ft > 500) {
      newErrors.fat = "Enter a value between 0 and 500";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [name, calories, protein, carbs, fat]);

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      if (!validate()) return;

      const payload = {
        name: name.trim(),
        calories: Math.round(Number(calories)),
        protein: Math.round(Number(protein)),
        carbs: Math.round(Number(carbs)),
        fat: Math.round(Number(fat)),
        frequency_per_week: frequency ? Number(frequency) : null,
        is_default: isDefault,
      };

      const callbacks = {
        onSuccess: () => {
          toast.success(isEdit ? "Preset updated" : "Preset created");
          onOpenChange(false);
        },
        onError: (err: unknown) => toast.error(getErrorMessage(err)),
      };

      if (isEdit && preset) {
        updateMutation.mutate(
          { presetId: preset.id, data: payload },
          callbacks,
        );
      } else {
        createMutation.mutate(
          { ...payload, trainee_id: traineeId },
          callbacks,
        );
      }
    },
    [
      name,
      calories,
      protein,
      carbs,
      fat,
      frequency,
      isDefault,
      isEdit,
      preset,
      traineeId,
      validate,
      createMutation,
      updateMutation,
      onOpenChange,
    ],
  );

  const handleOpenChange = useCallback(
    (nextOpen: boolean) => {
      if (!nextOpen && isPending) return;
      onOpenChange(nextOpen);
    },
    [isPending, onOpenChange],
  );

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent
        className="sm:max-w-md"
        onPointerDownOutside={(e) => {
          if (isPending) e.preventDefault();
        }}
        onEscapeKeyDown={(e) => {
          if (isPending) e.preventDefault();
        }}
      >
        <DialogHeader>
          <DialogTitle>
            {isEdit ? "Edit Macro Preset" : "Create Macro Preset"}
          </DialogTitle>
          <DialogDescription>
            {isEdit
              ? `Update "${preset.name}" for ${traineeName}`
              : `Create a new macro preset for ${traineeName}`}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="preset-name">Name</Label>
            <Input
              id="preset-name"
              type="text"
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                setErrors((prev) => ({ ...prev, name: "" }));
              }}
              placeholder="e.g. Training Day"
              maxLength={100}
              disabled={isPending}
              aria-invalid={Boolean(errors.name)}
              aria-describedby={errors.name ? "preset-name-error" : undefined}
            />
            {errors.name && (
              <p
                id="preset-name-error"
                className="text-sm text-destructive"
                role="alert"
              >
                {errors.name}
              </p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="preset-calories">Calories (kcal)</Label>
            <Input
              id="preset-calories"
              type="number"
              step="1"
              value={calories}
              onChange={(e) => {
                setCalories(e.target.value);
                setErrors((prev) => ({ ...prev, calories: "" }));
              }}
              placeholder="2000"
              min={500}
              max={10000}
              disabled={isPending}
              aria-invalid={Boolean(errors.calories)}
              aria-describedby={
                errors.calories ? "preset-calories-error" : undefined
              }
            />
            {errors.calories && (
              <p
                id="preset-calories-error"
                className="text-sm text-destructive"
                role="alert"
              >
                {errors.calories}
              </p>
            )}
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="space-y-2">
              <Label htmlFor="preset-protein">Protein (g)</Label>
              <Input
                id="preset-protein"
                type="number"
                step="1"
                value={protein}
                onChange={(e) => {
                  setProtein(e.target.value);
                  setErrors((prev) => ({ ...prev, protein: "" }));
                }}
                placeholder="150"
                min={0}
                max={500}
                disabled={isPending}
                aria-invalid={Boolean(errors.protein)}
                aria-describedby={
                  errors.protein ? "preset-protein-error" : undefined
                }
              />
              {errors.protein && (
                <p
                  id="preset-protein-error"
                  className="text-sm text-destructive"
                  role="alert"
                >
                  {errors.protein}
                </p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="preset-carbs">Carbs (g)</Label>
              <Input
                id="preset-carbs"
                type="number"
                step="1"
                value={carbs}
                onChange={(e) => {
                  setCarbs(e.target.value);
                  setErrors((prev) => ({ ...prev, carbs: "" }));
                }}
                placeholder="200"
                min={0}
                max={1000}
                disabled={isPending}
                aria-invalid={Boolean(errors.carbs)}
                aria-describedby={
                  errors.carbs ? "preset-carbs-error" : undefined
                }
              />
              {errors.carbs && (
                <p
                  id="preset-carbs-error"
                  className="text-sm text-destructive"
                  role="alert"
                >
                  {errors.carbs}
                </p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="preset-fat">Fat (g)</Label>
              <Input
                id="preset-fat"
                type="number"
                step="1"
                value={fat}
                onChange={(e) => {
                  setFat(e.target.value);
                  setErrors((prev) => ({ ...prev, fat: "" }));
                }}
                placeholder="70"
                min={0}
                max={500}
                disabled={isPending}
                aria-invalid={Boolean(errors.fat)}
                aria-describedby={
                  errors.fat ? "preset-fat-error" : undefined
                }
              />
              {errors.fat && (
                <p
                  id="preset-fat-error"
                  className="text-sm text-destructive"
                  role="alert"
                >
                  {errors.fat}
                </p>
              )}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="preset-frequency">Frequency</Label>
              <select
                id="preset-frequency"
                value={frequency}
                onChange={(e) => setFrequency(e.target.value)}
                disabled={isPending}
                aria-label="Preset frequency per week"
                className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-1 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {FREQUENCY_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex items-end space-x-2 pb-1">
              <input
                id="preset-default"
                type="checkbox"
                checked={isDefault}
                onChange={(e) => setIsDefault(e.target.checked)}
                disabled={isPending}
                className="h-4 w-4 shrink-0 rounded border-input accent-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-1 disabled:cursor-not-allowed disabled:opacity-50"
              />
              <Label htmlFor="preset-default" className="text-sm font-normal cursor-pointer">
                Set as default
              </Label>
            </div>
          </div>

          {calorieMismatchWarning && (
            <div className="flex items-start gap-2 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-200">
              <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true" />
              <p>{calorieMismatchWarning}</p>
            </div>
          )}

          <DialogFooter>
            <Button
              variant="outline"
              type="button"
              onClick={() => handleOpenChange(false)}
              disabled={isPending}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isPending}>
              {isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              {isEdit ? "Save Changes" : "Create Preset"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
