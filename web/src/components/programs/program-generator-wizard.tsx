"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { ArrowLeft, ArrowRight, Loader2, Wand2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useGenerateProgram } from "@/hooks/use-programs";
import { SplitTypeStep } from "./generator/split-type-step";
import { ConfigStep } from "./generator/config-step";
import { PreviewStep } from "./generator/preview-step";
import { getErrorMessage } from "@/lib/error-utils";
import type {
  SplitType,
  DifficultyLevel,
  GoalType,
  CustomDayConfig,
  GeneratedProgramResponse,
} from "@/types/program";

const STEPS = ["Split Type", "Configure", "Preview"] as const;
const DEFAULT_TRAINING_DAYS = ["Monday", "Tuesday", "Thursday", "Friday"];

export function ProgramGeneratorWizard() {
  const router = useRouter();
  const generateMutation = useGenerateProgram();

  // Wizard state
  const [step, setStep] = useState(0);
  const [splitType, setSplitType] = useState<SplitType | null>(null);
  const [difficulty, setDifficulty] = useState<DifficultyLevel | null>(null);
  const [goal, setGoal] = useState<GoalType | null>(null);
  const [durationWeeks, setDurationWeeks] = useState(4);
  const [trainingDays, setTrainingDays] = useState<string[]>(DEFAULT_TRAINING_DAYS);
  const [customDayConfig, setCustomDayConfig] = useState<CustomDayConfig[]>([]);

  // Preview state
  const [generatedData, setGeneratedData] =
    useState<GeneratedProgramResponse | null>(null);
  const [generateError, setGenerateError] = useState<string | null>(null);

  const trainingDaysPerWeek = trainingDays.length;

  const canAdvance = useCallback((): boolean => {
    if (step === 0) return splitType !== null;
    if (step === 1) {
      if (!difficulty || !goal) return false;
      if (trainingDays.length < 2) return false;
      if (splitType === "custom") {
        return (
          customDayConfig.length === trainingDaysPerWeek &&
          customDayConfig.every((d) => d.muscle_groups.length > 0)
        );
      }
      return true;
    }
    return false;
  }, [step, splitType, difficulty, goal, customDayConfig, trainingDays, trainingDaysPerWeek]);

  const triggerGeneration = useCallback(async () => {
    setGeneratedData(null);
    setGenerateError(null);

    try {
      const result = await generateMutation.mutateAsync({
        split_type: splitType!,
        difficulty: difficulty!,
        goal: goal!,
        duration_weeks: durationWeeks,
        training_days_per_week: trainingDaysPerWeek,
        training_days: trainingDays,
        custom_day_config:
          splitType === "custom" ? customDayConfig : undefined,
      });
      setGeneratedData(result);
    } catch (err) {
      setGenerateError(getErrorMessage(err));
    }
  }, [
    splitType,
    difficulty,
    goal,
    durationWeeks,
    trainingDaysPerWeek,
    trainingDays,
    customDayConfig,
    generateMutation,
  ]);

  const handleNext = useCallback(async () => {
    if (step < 2) {
      // If moving to preview step, trigger generation
      if (step === 1) {
        setStep(2);
        await triggerGeneration();
      } else {
        setStep(step + 1);
      }
    }
  }, [step, triggerGeneration]);

  const handleBack = () => {
    if (step > 0) {
      // Reset all generation state when leaving the preview step
      if (step === 2) {
        generateMutation.reset();
        setGeneratedData(null);
        setGenerateError(null);
      }
      setStep(step - 1);
    }
  };

  const handleOpenInBuilder = () => {
    if (!generatedData) return;

    // Store generated data in sessionStorage for the builder to pick up
    try {
      sessionStorage.setItem(
        "generated-program",
        JSON.stringify(generatedData),
      );
    } catch {
      toast.error("Failed to store program data. Please try again.");
      return;
    }
    router.push("/programs/new?from=generator");
    toast.success("Program loaded into builder — customize and save!");
  };

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      {/* Step indicator */}
      <nav aria-label="Program generator progress">
        <ol className="flex items-center gap-2">
          {STEPS.map((label, i) => (
            <li key={label} className="flex items-center gap-2">
              {i > 0 && (
                <div className="h-px w-8 bg-border" aria-hidden="true" />
              )}
              <button
                aria-current={step === i ? "step" : undefined}
                aria-label={`Step ${i + 1}: ${label}${step > i ? " (completed)" : step === i ? " (current)" : ""}`}
                className={`flex h-8 items-center gap-1.5 rounded-full px-3 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 ${
                  step === i
                    ? "bg-primary text-primary-foreground"
                    : step > i
                      ? "bg-primary/10 text-primary"
                      : "bg-muted text-muted-foreground"
                }`}
                onClick={() => {
                  if (i < step) {
                    // Reset all generation state when leaving the preview step
                    if (step === 2) {
                      generateMutation.reset();
                      setGeneratedData(null);
                      setGenerateError(null);
                    }
                    setStep(i);
                  }
                }}
                disabled={i > step}
              >
                <span aria-hidden="true">{i + 1}</span>
                <span className="hidden sm:inline">{label}</span>
              </button>
            </li>
          ))}
        </ol>
      </nav>

      {/* Step content */}
      <div className="min-h-[300px]">
        {step === 0 && (
          <SplitTypeStep value={splitType} onChange={setSplitType} />
        )}
        {step === 1 && splitType && (
          <ConfigStep
            splitType={splitType}
            difficulty={difficulty}
            goal={goal}
            durationWeeks={durationWeeks}
            trainingDays={trainingDays}
            customDayConfig={customDayConfig}
            onDifficultyChange={setDifficulty}
            onGoalChange={setGoal}
            onDurationChange={setDurationWeeks}
            onTrainingDaysChange={setTrainingDays}
            onCustomDayConfigChange={setCustomDayConfig}
          />
        )}
        {step === 2 && (
          <PreviewStep
            data={generatedData}
            isLoading={generateMutation.isPending}
            error={generateError}
            onRetry={() => {
              generateMutation.reset();
              triggerGeneration();
            }}
          />
        )}
      </div>

      {/* Navigation buttons */}
      <div className="flex justify-between border-t pt-4">
        <Button
          variant="ghost"
          onClick={handleBack}
          disabled={step === 0}
        >
          <ArrowLeft className="mr-2 h-4 w-4" aria-hidden="true" />
          Back
        </Button>

        {step < 2 ? (
          <Button onClick={handleNext} disabled={!canAdvance() || generateMutation.isPending}>
            {step === 1 ? (
              <>
                <Wand2 className="mr-2 h-4 w-4" aria-hidden="true" />
                Generate with AI
              </>
            ) : (
              <>
                Next
                <ArrowRight className="ml-2 h-4 w-4" aria-hidden="true" />
              </>
            )}
          </Button>
        ) : (
          <Button
            onClick={handleOpenInBuilder}
            disabled={!generatedData || generateMutation.isPending}
          >
            {generateMutation.isPending ? (
              <>
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
                AI is generating...
              </>
            ) : (
              "Open in Builder"
            )}
          </Button>
        )}
      </div>
    </div>
  );
}
