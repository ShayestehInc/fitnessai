"use client";

import {
  SplitType,
  SPLIT_LABELS,
  SPLIT_DESCRIPTIONS,
} from "@/types/program";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import {
  ArrowLeftRight,
  Dumbbell,
  LayoutGrid,
  Layers,
  Settings2,
} from "lucide-react";

const SPLIT_ICONS: Record<SplitType, React.ElementType> = {
  ppl: Layers,
  upper_lower: ArrowLeftRight,
  full_body: Dumbbell,
  bro_split: LayoutGrid,
  custom: Settings2,
};

interface SplitTypeStepProps {
  value: SplitType | null;
  onChange: (split: SplitType) => void;
}

export function SplitTypeStep({ value, onChange }: SplitTypeStepProps) {
  const splits = Object.values(SplitType);

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold">Choose a split type</h3>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {splits.map((split) => {
          const Icon = SPLIT_ICONS[split];
          const selected = value === split;
          return (
            <Card
              key={split}
              role="button"
              tabIndex={0}
              aria-pressed={selected}
              className={cn(
                "cursor-pointer transition-all hover:border-primary/50",
                selected && "border-primary ring-2 ring-primary/20",
              )}
              onClick={() => onChange(split)}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  onChange(split);
                }
              }}
            >
              <CardContent className="flex flex-col gap-2 p-4">
                <div className="flex items-center gap-2">
                  <Icon className="h-5 w-5 text-primary" aria-hidden="true" />
                  <span className="font-medium">{SPLIT_LABELS[split]}</span>
                </div>
                <p className="text-sm text-muted-foreground">
                  {SPLIT_DESCRIPTIONS[split]}
                </p>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
