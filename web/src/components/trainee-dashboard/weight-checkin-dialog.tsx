"use client";

import { useState } from "react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useCreateWeightCheckIn } from "@/hooks/use-trainee-dashboard";
import { ApiError } from "@/lib/api-client";

interface WeightCheckInDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

function getTodayString(): string {
  const d = new Date();
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function WeightCheckInDialog({
  open,
  onOpenChange,
}: WeightCheckInDialogProps) {
  const [weight, setWeight] = useState("");
  const [date, setDate] = useState(getTodayString);
  const [notes, setNotes] = useState("");
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const createMutation = useCreateWeightCheckIn();

  function resetForm() {
    setWeight("");
    setDate(getTodayString());
    setNotes("");
    setFieldErrors({});
  }

  function validate(): boolean {
    const errors: Record<string, string> = {};
    const weightNum = parseFloat(weight);

    if (!weight || isNaN(weightNum)) {
      errors.weight_kg = "Weight is required";
    } else if (weightNum < 20 || weightNum > 500) {
      errors.weight_kg = "Weight must be between 20 and 500 kg";
    }

    if (!date) {
      errors.date = "Date is required";
    } else {
      const selected = new Date(date + "T00:00:00");
      const today = new Date();
      today.setHours(23, 59, 59, 999);
      if (selected > today) {
        errors.date = "Date cannot be in the future";
      }
    }

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;

    createMutation.mutate(
      {
        date,
        weight_kg: parseFloat(weight),
        notes: notes.trim() || undefined,
      },
      {
        onSuccess: () => {
          toast.success("Weight check-in saved");
          resetForm();
          onOpenChange(false);
        },
        onError: (error) => {
          if (error instanceof ApiError && error.body) {
            const body = error.body as Record<string, string[] | string>;
            const parsed: Record<string, string> = {};
            for (const [key, value] of Object.entries(body)) {
              if (Array.isArray(value)) {
                parsed[key] = value[0];
              } else if (typeof value === "string") {
                parsed[key] = value;
              }
            }
            if (Object.keys(parsed).length > 0) {
              setFieldErrors(parsed);
              return;
            }
          }
          toast.error("Failed to save weight check-in");
        },
      },
    );
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!v) resetForm();
        onOpenChange(v);
      }}
    >
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Log Weight</DialogTitle>
          <DialogDescription>
            Record your weight check-in.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="weight-input">Weight (kg)</Label>
            <Input
              id="weight-input"
              type="number"
              step="0.1"
              min="20"
              max="500"
              placeholder="75.0"
              value={weight}
              onChange={(e) => {
                setWeight(e.target.value);
                setFieldErrors((prev) => {
                  const next = { ...prev };
                  delete next.weight_kg;
                  return next;
                });
              }}
              aria-invalid={!!fieldErrors.weight_kg}
              aria-describedby={fieldErrors.weight_kg ? "weight-error" : undefined}
            />
            {fieldErrors.weight_kg && (
              <p id="weight-error" className="text-sm text-destructive" role="alert">
                {fieldErrors.weight_kg}
              </p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="date-input">Date</Label>
            <Input
              id="date-input"
              type="date"
              value={date}
              max={getTodayString()}
              onChange={(e) => {
                setDate(e.target.value);
                setFieldErrors((prev) => {
                  const next = { ...prev };
                  delete next.date;
                  return next;
                });
              }}
              aria-invalid={!!fieldErrors.date}
              aria-describedby={fieldErrors.date ? "date-error" : undefined}
            />
            {fieldErrors.date && (
              <p id="date-error" className="text-sm text-destructive" role="alert">
                {fieldErrors.date}
              </p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="notes-input">Notes (optional)</Label>
            <Textarea
              id="notes-input"
              placeholder="e.g. Morning, after fasting"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={2}
            />
          </div>

          {fieldErrors.non_field_errors && (
            <p className="text-sm text-destructive" role="alert">
              {fieldErrors.non_field_errors}
            </p>
          )}

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                resetForm();
                onOpenChange(false);
              }}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={createMutation.isPending}>
              {createMutation.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              Save
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
