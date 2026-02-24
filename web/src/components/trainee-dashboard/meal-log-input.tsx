"use client";

import { useState, useRef, useEffect, useId } from "react";
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
/** Show character count when the user is within this many characters of the limit. */
const CHAR_COUNT_THRESHOLD = 200;

interface MealLogInputProps {
  date: string;
}

export function MealLogInput({ date }: MealLogInputProps) {
  const [input, setInput] = useState("");
  const [parsedResult, setParsedResult] = useState<ParseNaturalLanguageResponse | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const helpTextId = useId();
  const charCountId = useId();

  const parseMutation = useParseNaturalLanguage();
  const confirmMutation = useConfirmAndSaveMeal(date);

  const isParsing = parseMutation.isPending;
  const isConfirming = confirmMutation.isPending;
  const trimmedInput = input.trim();
  const isInputValid = trimmedInput.length > 0 && trimmedInput.length <= MAX_INPUT_LENGTH;
  const isOverLimit = input.length > MAX_INPUT_LENGTH;
  const isNearLimit = input.length >= MAX_INPUT_LENGTH - CHAR_COUNT_THRESHOLD;
  const parsedMeals = parsedResult?.nutrition?.meals ?? [];
  const needsClarification = parsedResult?.needs_clarification;

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
      // If parsed results are shown and ready to confirm, Enter confirms
      if (parsedMeals.length > 0 && !needsClarification && !isConfirming) {
        handleConfirm();
      } else {
        handleSubmit();
      }
    }
    if (e.key === "Escape" && parsedResult) {
      e.preventDefault();
      handleCancel();
    }
  }

  // Clear stale parse error state when user starts typing new input
  useEffect(() => {
    if (input.length > 0 && parseMutation.isError) {
      parseMutation.reset();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [input]);

  // Clear parsed result and input when date changes
  useEffect(() => {
    setParsedResult(null);
    setInput("");
  }, [date]);

  const describedByIds = [helpTextId, isNearLimit ? charCountId : ""]
    .filter(Boolean)
    .join(" ");

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Sparkles className="h-4 w-4" aria-hidden="true" />
          Log Food
        </CardTitle>
        <p id={helpTextId} className="text-sm text-muted-foreground">
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
            placeholder='e.g., "2 eggs, toast, orange juice"'
            disabled={isParsing}
            aria-label="Describe your meal"
            aria-describedby={describedByIds || undefined}
            aria-invalid={isOverLimit || undefined}
          />
          <Button
            onClick={handleSubmit}
            disabled={!isInputValid || isParsing}
            size="icon"
            aria-label={isParsing ? "Analyzing your meal..." : "Analyze meal"}
          >
            {isParsing ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Send className="h-4 w-4" />
            )}
          </Button>
        </div>

        {/* Character count — visible when approaching or exceeding limit */}
        {isNearLimit && (
          <p
            id={charCountId}
            className={`text-xs ${isOverLimit ? "text-destructive" : "text-muted-foreground"}`}
            role={isOverLimit ? "alert" : undefined}
          >
            {input.length} / {MAX_INPUT_LENGTH} characters
            {isOverLimit && " — please shorten your description"}
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
              aria-label="Dismiss clarification"
            >
              <X className="h-3 w-3" />
            </Button>
          </div>
        )}

        {/* Parsed Results */}
        {parsedMeals.length > 0 && !needsClarification && (
          <div className="space-y-3">
            <p className="text-sm font-medium">
              Detected {parsedMeals.length} {parsedMeals.length === 1 ? "item" : "items"}
            </p>
            <div className="space-y-2" role="list" aria-label="Detected food items">
              {parsedMeals.map((meal, index) => (
                <div
                  key={`${meal.name}-${meal.calories}-${index}`}
                  role="listitem"
                  className="flex flex-wrap items-center justify-between gap-1 rounded-md border bg-muted/30 px-3 py-2"
                >
                  <span className="min-w-0 truncate text-sm font-medium">
                    {meal.name}
                  </span>
                  <div className="ml-auto flex flex-wrap gap-x-3 gap-y-0.5 text-xs text-muted-foreground">
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
              ))}
            </div>
          </div>
        )}
      </CardContent>

      {/* Confirm / Cancel */}
      {parsedMeals.length > 0 && !needsClarification && (
        <CardFooter className="flex flex-col items-end gap-2 pt-0">
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={handleCancel}
              disabled={isConfirming}
              aria-label="Cancel and discard detected items"
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
          </div>
          <p className="hidden text-[11px] text-muted-foreground sm:block">
            Press <kbd className="rounded border px-1 py-0.5 text-[10px] font-mono">Enter</kbd> to confirm
            or <kbd className="rounded border px-1 py-0.5 text-[10px] font-mono">Esc</kbd> to cancel
          </p>
        </CardFooter>
      )}
    </Card>
  );
}
