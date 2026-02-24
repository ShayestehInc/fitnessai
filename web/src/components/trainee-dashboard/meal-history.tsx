"use client";

import { useState, useCallback } from "react";
import { Trash2, UtensilsCrossed } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useDeleteMealEntry } from "@/hooks/use-trainee-nutrition";
import { useTraineeTodayLog } from "@/hooks/use-trainee-dashboard";
import type { NutritionMeal } from "@/types/trainee-view";

interface MealHistoryProps {
  meals: NutritionMeal[];
  date: string;
}

export function MealHistory({ meals, date }: MealHistoryProps) {
  const [deleteIndex, setDeleteIndex] = useState<number | null>(null);
  const deleteMutation = useDeleteMealEntry(date);
  const { data: todayLogs } = useTraineeTodayLog(date);

  const dailyLogId = todayLogs?.[0]?.id ?? null;

  const handleDelete = useCallback(() => {
    if (deleteIndex === null || dailyLogId === null) return;

    deleteMutation.mutate(
      { logId: dailyLogId, entry_index: deleteIndex },
      {
        onSuccess: () => {
          toast.success("Meal removed");
          setDeleteIndex(null);
        },
        onError: () => {
          toast.error("Failed to remove meal.");
          setDeleteIndex(null);
        },
      },
    );
  }, [deleteIndex, dailyLogId, deleteMutation]);

  return (
    <>
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <UtensilsCrossed className="h-4 w-4" aria-hidden="true" />
            Meals
          </CardTitle>
          {meals.length > 0 && (
            <p className="text-sm text-muted-foreground">
              {meals.length} {meals.length === 1 ? "meal" : "meals"} logged
            </p>
          )}
        </CardHeader>
        <CardContent>
          {meals.length === 0 ? (
            <div className="py-6 text-center">
              <p className="text-sm text-muted-foreground">
                No meals logged yet. Use the input above to log your food.
              </p>
            </div>
          ) : (
            <div className="space-y-2" role="list" aria-label="Logged meals">
              {meals.map((meal, index) => (
                <div
                  key={index}
                  role="listitem"
                  className="flex items-center justify-between rounded-md border px-3 py-2"
                >
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium">{meal.name}</p>
                    <div className="flex gap-3 text-xs text-muted-foreground">
                      <span>{Math.round(meal.calories)} kcal</span>
                      <span>P: {Math.round(meal.protein)}g</span>
                      <span>C: {Math.round(meal.carbs)}g</span>
                      <span>F: {Math.round(meal.fat)}g</span>
                    </div>
                  </div>
                  {dailyLogId !== null && (
                    <Button
                      variant="ghost"
                      size="icon"
                      className="ml-2 h-7 w-7 shrink-0 text-muted-foreground hover:text-destructive"
                      onClick={() => setDeleteIndex(index)}
                      aria-label={`Remove ${meal.name}`}
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  )}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteIndex !== null}
        onOpenChange={(open) => {
          if (!open) setDeleteIndex(null);
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Remove this meal?</DialogTitle>
            <DialogDescription>
              {deleteIndex !== null && meals[deleteIndex]
                ? `"${meals[deleteIndex].name}" will be removed from your log.`
                : "This meal will be removed from your log."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setDeleteIndex(null)}
              disabled={deleteMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={deleteMutation.isPending}
            >
              {deleteMutation.isPending ? "Removing..." : "Remove"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
