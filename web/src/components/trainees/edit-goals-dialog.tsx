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
import { useUpdateTraineeGoals } from "@/hooks/use-trainee-goals";
import { getErrorMessage } from "@/lib/error-utils";
import type { NutritionGoal } from "@/types/trainer";

interface EditGoalsDialogProps {
  traineeId: number;
  traineeName: string;
  currentGoals: NutritionGoal | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function EditGoalsDialog({
  traineeId,
  traineeName,
  currentGoals,
  open,
  onOpenChange,
}: EditGoalsDialogProps) {
  const [calories, setCalories] = useState("");
  const [protein, setProtein] = useState("");
  const [carbs, setCarbs] = useState("");
  const [fat, setFat] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});

  const updateMutation = useUpdateTraineeGoals(traineeId);

  useEffect(() => {
    if (open && currentGoals) {
      setCalories(String(Math.round(currentGoals.calories_goal)));
      setProtein(String(Math.round(currentGoals.protein_goal)));
      setCarbs(String(Math.round(currentGoals.carbs_goal)));
      setFat(String(Math.round(currentGoals.fat_goal)));
      setErrors({});
    }
  }, [open, currentGoals]);

  const validate = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    const cal = Number(calories);
    const pro = Number(protein);
    const crb = Number(carbs);
    const ft = Number(fat);

    if (!calories || isNaN(cal) || cal < 500 || cal > 10000) {
      newErrors.calories = "Enter a value between 500 and 10000";
    }
    if (!protein || isNaN(pro) || pro < 0 || pro > 500) {
      newErrors.protein = "Enter a value between 0 and 500";
    }
    if (!carbs || isNaN(crb) || crb < 0 || crb > 1000) {
      newErrors.carbs = "Enter a value between 0 and 1000";
    }
    if (!fat || isNaN(ft) || ft < 0 || ft > 500) {
      newErrors.fat = "Enter a value between 0 and 500";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [calories, protein, carbs, fat]);

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      if (!validate()) return;

      updateMutation.mutate(
        {
          calories_goal: Number(calories),
          protein_goal: Number(protein),
          carbs_goal: Number(carbs),
          fat_goal: Number(fat),
        },
        {
          onSuccess: () => {
            toast.success("Nutrition goals updated");
            onOpenChange(false);
          },
          onError: (err) => toast.error(getErrorMessage(err)),
        },
      );
    },
    [calories, protein, carbs, fat, validate, updateMutation, onOpenChange],
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Edit Nutrition Goals</DialogTitle>
          <DialogDescription>
            Adjust daily macro targets for {traineeName}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="goal-calories">Calories (kcal)</Label>
            <Input
              id="goal-calories"
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
              <Label htmlFor="goal-protein">Protein (g)</Label>
              <Input
                id="goal-protein"
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
              <Label htmlFor="goal-carbs">Carbs (g)</Label>
              <Input
                id="goal-carbs"
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
              <Label htmlFor="goal-fat">Fat (g)</Label>
              <Input
                id="goal-fat"
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

          <DialogFooter>
            <Button
              variant="outline"
              type="button"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={updateMutation.isPending}>
              {updateMutation.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
              )}
              Save Goals
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
