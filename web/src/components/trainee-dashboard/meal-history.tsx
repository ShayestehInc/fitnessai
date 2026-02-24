"use client";

import { useState, useCallback } from "react";
import { Trash2, UtensilsCrossed, Loader2 } from "lucide-react";
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
  // Store both the index and the name of the meal targeted for deletion.
  // Capturing the name at dialog-open time prevents stale-index issues if
  // the meals array is reordered by a background react-query refetch.
  const [deleteTarget, setDeleteTarget] = useState<{
    index: number;
    name: string;
  } | null>(null);
  const deleteMutation = useDeleteMealEntry(date);
  const { data: todayLogs, isLoading: isLoadingLogs } = useTraineeTodayLog(date);

  const dailyLogId = todayLogs?.[0]?.id ?? null;
  const isDeleting = deleteMutation.isPending;

  const openDeleteDialog = useCallback(
    (index: number, mealName: string) => {
      setDeleteTarget({ index, name: mealName });
    },
    [],
  );

  const closeDeleteDialog = useCallback(() => {
    if (!isDeleting) setDeleteTarget(null);
  }, [isDeleting]);

  const handleDelete = useCallback(() => {
    if (deleteTarget === null || dailyLogId === null) return;

    deleteMutation.mutate(
      { logId: dailyLogId, entry_index: deleteTarget.index },
      {
        onSuccess: () => {
          toast.success("Meal removed");
          setDeleteTarget(null);
        },
        onError: () => {
          toast.error("Failed to remove meal.");
          setDeleteTarget(null);
        },
      },
    );
    // deleteMutation.mutate is referentially stable in React Query v5
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [deleteTarget, dailyLogId]);

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
            <div className="flex flex-col items-center py-8 text-center">
              <UtensilsCrossed
                className="mb-2 h-8 w-8 text-muted-foreground/40"
                aria-hidden="true"
              />
              <p className="text-sm text-muted-foreground">
                No meals logged yet. Use the input above to log your food.
              </p>
            </div>
          ) : (
            <div className="space-y-2" role="list" aria-label="Logged meals">
              {meals.map((meal, index) => (
                <div
                  key={`${meal.name}-${Math.round(meal.calories)}-${meal.timestamp ?? index}`}
                  role="listitem"
                  className="flex items-center justify-between rounded-md border px-3 py-2"
                >
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium">{meal.name}</p>
                    <div className="flex flex-wrap gap-3 text-xs text-muted-foreground">
                      <span>{Math.round(meal.calories)} kcal</span>
                      <span aria-label={`Protein: ${Math.round(meal.protein)} grams`}>
                        P: {Math.round(meal.protein)}g
                      </span>
                      <span aria-label={`Carbs: ${Math.round(meal.carbs)} grams`}>
                        C: {Math.round(meal.carbs)}g
                      </span>
                      <span aria-label={`Fat: ${Math.round(meal.fat)} grams`}>
                        F: {Math.round(meal.fat)}g
                      </span>
                    </div>
                  </div>
                  {isLoadingLogs ? (
                    <Loader2 className="ml-2 h-3.5 w-3.5 shrink-0 animate-spin text-muted-foreground" />
                  ) : dailyLogId !== null ? (
                    <Button
                      variant="ghost"
                      size="icon"
                      className="ml-2 h-8 w-8 shrink-0 text-muted-foreground hover:text-destructive"
                      onClick={() => openDeleteDialog(index, meal.name)}
                      disabled={isDeleting}
                      aria-label={`Remove ${meal.name}`}
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  ) : null}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteTarget !== null}
        onOpenChange={(open) => {
          if (!open) closeDeleteDialog();
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Remove this meal?</DialogTitle>
            <DialogDescription>
              {deleteTarget
                ? `"${deleteTarget.name}" will be removed from your log.`
                : "This meal will be removed from your log."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={closeDeleteDialog}
              disabled={isDeleting}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={isDeleting}
            >
              {isDeleting ? "Removing..." : "Remove"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
