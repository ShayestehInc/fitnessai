"use client";

import { useState, useRef, useEffect } from "react";
import { Send, Loader2, X, AlertTriangle, Sparkles } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  useParseNaturalLanguage,
  useConfirmAndSaveMeal,
} from "@/hooks/use-trainee-nutrition";
import type { ParseNaturalLanguageResponse } from "@/types/trainee-dashboard";

const MAX_INPUT_LENGTH = 2000;

interface MealLogInputProps {
  date: string;
}

export function MealLogInput({ date }: MealLogInputProps) {
  const [input, setInput] = useState("");
  const [parsedResult, setParsedResult] = useState<ParseNaturalLanguageResponse | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const parseMutation = useParseNaturalLanguage();
  const confirmMutation = useConfirmAndSaveMeal(date);

  const isParsing = parseMutation.isPending;
  const isConfirming = confirmMutation.isPending;
  const trimmedInput = input.trim();
  const isInputValid = trimmedInput.length > 0 && trimmedInput.length <= MAX_INPUT_LENGTH;
  const isOverLimit = input.length > MAX_INPUT_LENGTH;

  function handleSubmit() {
    if (!isInputValid || isParsing) return;

    parseMutation.mutate(
      { user_input: trimmedInput, date },
      {
        onSuccess: (data) => {
          if (data.needs_clarification && data.clarification_question) {
            setParsedResult(data);
            return;
          }

          const meals = data.nutrition?.meals;
          if (!meals || meals.length === 0) {
            toast.error("No food items detected. Try being more specific.");
            return;
          }

          setParsedResult(data);
        },
        onError: (error) => {
          const message =
            typeof error === "object" && error !== null && "status" in error
              ? "Couldn't understand that. Try rephrasing."
              : "Something went wrong. Please try again.";
          toast.error(message);
        },
      },
    );
  }

  function handleConfirm() {
    if (!parsedResult || isConfirming) return;

    confirmMutation.mutate(
      { parsed_data: parsedResult, date, confirm: true },
      {
        onSuccess: () => {
          toast.success("Meal logged!");
          setParsedResult(null);
          setInput("");
          inputRef.current?.focus();
        },
        onError: () => {
          toast.error("Failed to save meal. Please try again.");
        },
      },
    );
  }

  function handleCancel() {
    setParsedResult(null);
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
    if (e.key === "Escape" && parsedResult) {
      e.preventDefault();
      handleCancel();
    }
  }

  // Clear parsed result and input when date changes
  useEffect(() => {
    setParsedResult(null);
    setInput("");
  }, [date]);

  const parsedMeals = parsedResult?.nutrition?.meals ?? [];
  const needsClarification = parsedResult?.needs_clarification;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Sparkles className="h-4 w-4" aria-hidden="true" />
          Log Food
        </CardTitle>
        <p className="text-sm text-muted-foreground">
          Describe what you ate in natural language
        </p>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Input */}
        <div className="flex gap-2">
          <Input
            ref={inputRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder='e.g., "2 eggs, toast, and a glass of orange juice"'
            disabled={isParsing}
            aria-label="Describe your meal"
            aria-invalid={isOverLimit}
          />
          <Button
            onClick={handleSubmit}
            disabled={!isInputValid || isParsing}
            size="icon"
            aria-label="Parse meal"
          >
            {isParsing ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Send className="h-4 w-4" />
            )}
          </Button>
        </div>

        {isOverLimit && (
          <p className="text-xs text-destructive" role="alert">
            Input exceeds {MAX_INPUT_LENGTH} character limit ({input.length}/{MAX_INPUT_LENGTH})
          </p>
        )}

        {/* Clarification Needed */}
        {needsClarification && parsedResult?.clarification_question && (
          <div
            className="flex items-start gap-3 rounded-lg border border-amber-200 bg-amber-50 p-3 dark:border-amber-800 dark:bg-amber-950/30"
            role="alert"
          >
            <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-amber-600" aria-hidden="true" />
            <div className="space-y-1">
              <p className="text-sm font-medium text-amber-800 dark:text-amber-200">
                Need more details
              </p>
              <p className="text-sm text-amber-700 dark:text-amber-300">
                {parsedResult.clarification_question}
              </p>
            </div>
            <Button
              variant="ghost"
              size="icon"
              className="ml-auto h-6 w-6 shrink-0"
              onClick={handleCancel}
              aria-label="Dismiss"
            >
              <X className="h-3 w-3" />
            </Button>
          </div>
        )}

        {/* Parsed Results */}
        {parsedMeals.length > 0 && !needsClarification && (
          <div className="space-y-3">
            <p className="text-sm font-medium">
              Parsed items ({parsedMeals.length})
            </p>
            <div className="space-y-2">
              {parsedMeals.map((meal, index) => (
                <div
                  key={`${meal.name}-${meal.calories}-${index}`}
                  className="flex items-center justify-between rounded-md border bg-muted/30 px-3 py-2"
                >
                  <span className="text-sm font-medium">{meal.name}</span>
                  <div className="flex gap-3 text-xs text-muted-foreground">
                    <span>{Math.round(meal.calories)} kcal</span>
                    <span>P: {Math.round(meal.protein)}g</span>
                    <span>C: {Math.round(meal.carbs)}g</span>
                    <span>F: {Math.round(meal.fat)}g</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </CardContent>

      {/* Confirm / Cancel */}
      {parsedMeals.length > 0 && !needsClarification && (
        <CardFooter className="flex justify-end gap-2 pt-0">
          <Button
            variant="outline"
            size="sm"
            onClick={handleCancel}
            disabled={isConfirming}
          >
            Cancel
          </Button>
          <Button
            size="sm"
            onClick={handleConfirm}
            disabled={isConfirming}
          >
            {isConfirming ? (
              <>
                <Loader2 className="mr-2 h-3 w-3 animate-spin" />
                Saving...
              </>
            ) : (
              "Confirm & Save"
            )}
          </Button>
        </CardFooter>
      )}
    </Card>
  );
}
