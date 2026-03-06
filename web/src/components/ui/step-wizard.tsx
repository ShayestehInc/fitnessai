"use client";

import * as React from "react";
import { useState, useCallback } from "react";
import { Check, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { useLocale } from "@/providers/locale-provider";

export interface WizardStep {
  label: string;
  description?: string;
  content: React.ReactNode;
  validate?: () => boolean;
}

interface StepWizardProps {
  steps: WizardStep[];
  onComplete: () => void | Promise<void>;
  onCancel: () => void;
  title: string;
  submitLabel?: string;
  isSubmitting?: boolean;
}

export function StepWizard({
  steps,
  onComplete,
  onCancel,
  title,
  submitLabel = "Submit",
  isSubmitting = false,
}: StepWizardProps) {
  const { t } = useLocale();
  const [currentStep, setCurrentStep] = useState(0);

  const isLastStep = currentStep === steps.length - 1;
  const step = steps[currentStep];

  const handleNext = useCallback(() => {
    if (step?.validate && !step.validate()) return;
    if (isLastStep) {
      onComplete();
    } else {
      setCurrentStep((s) => s + 1);
    }
  }, [step, isLastStep, onComplete]);

  const handleBack = useCallback(() => {
    setCurrentStep((s) => Math.max(0, s - 1));
  }, []);

  return (
    <div className="mx-auto w-full max-w-3xl space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight">{title}</h1>
      </div>

      {/* Stepper */}
      <nav aria-label={t("nav.progress")}>
        <ol className="flex items-center">
          {steps.map((s, index) => {
            const isCompleted = index < currentStep;
            const isCurrent = index === currentStep;

            return (
              <li
                key={s.label}
                className={cn(
                  "flex items-center",
                  index < steps.length - 1 && "flex-1",
                )}
              >
                <div className="flex items-center gap-2">
                  <span
                    className={cn(
                      "flex h-8 w-8 shrink-0 items-center justify-center rounded-full border-2 text-xs font-semibold transition-colors",
                      isCompleted &&
                        "border-primary bg-primary text-primary-foreground",
                      isCurrent &&
                        "border-primary text-primary",
                      !isCompleted &&
                        !isCurrent &&
                        "border-muted-foreground/30 text-muted-foreground/50",
                    )}
                  >
                    {isCompleted ? (
                      <Check className="h-4 w-4" aria-hidden="true" />
                    ) : (
                      index + 1
                    )}
                  </span>
                  <span
                    className={cn(
                      "hidden text-sm font-medium sm:inline",
                      isCurrent
                        ? "text-foreground"
                        : "text-muted-foreground",
                    )}
                  >
                    {s.label}
                  </span>
                </div>
                {index < steps.length - 1 && (
                  <div
                    className={cn(
                      "mx-3 h-px flex-1",
                      isCompleted ? "bg-primary" : "bg-border",
                    )}
                  />
                )}
              </li>
            );
          })}
        </ol>
      </nav>

      {/* Step content */}
      <div className="min-h-[300px]">
        {step?.description && (
          <p className="mb-4 text-sm text-muted-foreground">
            {step.description}
          </p>
        )}
        {step?.content}
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between border-t pt-4">
        <Button type="button" variant="ghost" onClick={onCancel}>
          Cancel
        </Button>
        <div className="flex gap-2">
          {currentStep > 0 && (
            <Button
              type="button"
              variant="outline"
              onClick={handleBack}
              disabled={isSubmitting}
            >
              Back
            </Button>
          )}
          <Button
            type="button"
            onClick={handleNext}
            disabled={isSubmitting}
          >
            {isSubmitting && (
              <Loader2
                className="mr-2 h-4 w-4 animate-spin"
                aria-hidden="true"
              />
            )}
            {isLastStep ? submitLabel : "Next"}
          </Button>
        </div>
      </div>
    </div>
  );
}
