"use client";

import { useCallback, useEffect, useState } from "react";
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

    const cal = Number(calories);
    if (!calories || isNaN(cal) || cal < 500 || cal > 10000) {
      newErrors.calories = "Enter a value between 500 and 10,000";
    }

    const pro = Number(protein);
    if (protein === "" || isNaN(pro) || pro < 0 || pro > 500) {
      newErrors.protein = "Enter a value between 0 and 500";
    }

    const crb = Number(carbs);
    if (carbs === "" || isNaN(crb) || crb < 0 || crb > 1000) {
      newErrors.carbs = "Enter a value between 0 and 1,000";
    }

    const ft = Number(fat);
    if (fat === "" || isNaN(ft) || ft < 0 || ft > 500) {
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
        calories: Number(calories),
        protein: Number(protein),
        carbs: Number(carbs),
        fat: Number(fat),
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

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
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
              aria-invalid={Boolean(errors.name)}
            />
            {errors.name && (
              <p className="text-sm text-destructive">{errors.name}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="preset-calories">Calories (kcal)</Label>
            <Input
              id="preset-calories"
              type="number"
              value={calories}
              onChange={(e) => {
                setCalories(e.target.value);
                setErrors((prev) => ({ ...prev, calories: "" }));
              }}
              placeholder="2000"
              min={500}
              max={10000}
              aria-invalid={Boolean(errors.calories)}
            />
            {errors.calories && (
              <p className="text-sm text-destructive">{errors.calories}</p>
            )}
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="space-y-2">
              <Label htmlFor="preset-protein">Protein (g)</Label>
              <Input
                id="preset-protein"
                type="number"
                value={protein}
                onChange={(e) => {
                  setProtein(e.target.value);
                  setErrors((prev) => ({ ...prev, protein: "" }));
                }}
                placeholder="150"
                min={0}
                max={500}
                aria-invalid={Boolean(errors.protein)}
              />
              {errors.protein && (
                <p className="text-sm text-destructive">{errors.protein}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="preset-carbs">Carbs (g)</Label>
              <Input
                id="preset-carbs"
                type="number"
                value={carbs}
                onChange={(e) => {
                  setCarbs(e.target.value);
                  setErrors((prev) => ({ ...prev, carbs: "" }));
                }}
                placeholder="200"
                min={0}
                max={1000}
                aria-invalid={Boolean(errors.carbs)}
              />
              {errors.carbs && (
                <p className="text-sm text-destructive">{errors.carbs}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="preset-fat">Fat (g)</Label>
              <Input
                id="preset-fat"
                type="number"
                value={fat}
                onChange={(e) => {
                  setFat(e.target.value);
                  setErrors((prev) => ({ ...prev, fat: "" }));
                }}
                placeholder="70"
                min={0}
                max={500}
                aria-invalid={Boolean(errors.fat)}
              />
              {errors.fat && (
                <p className="text-sm text-destructive">{errors.fat}</p>
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
                className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
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
                className="h-4 w-4 rounded border-input"
              />
              <Label htmlFor="preset-default" className="text-sm font-normal">
                Set as default
              </Label>
            </div>
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              type="button"
              onClick={() => onOpenChange(false)}
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
