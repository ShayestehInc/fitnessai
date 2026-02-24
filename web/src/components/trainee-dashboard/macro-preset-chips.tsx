"use client";

import { Zap } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { useTraineeMacroPresets } from "@/hooks/use-trainee-nutrition";
import type { MacroValues } from "@/types/trainee-view";

interface MacroPresetChipsProps {
  currentGoals: MacroValues;
}

export function MacroPresetChips({ currentGoals }: MacroPresetChipsProps) {
  const { data: presets } = useTraineeMacroPresets();

  if (!presets || presets.length === 0) return null;

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="flex items-center gap-1 text-xs font-medium text-muted-foreground">
        <Zap className="h-3 w-3" aria-hidden="true" />
        Presets
      </span>
      <TooltipProvider delayDuration={200}>
        {presets.map((preset) => {
          const isActive =
            Math.round(preset.calories) === Math.round(currentGoals.calories) &&
            Math.round(preset.protein) === Math.round(currentGoals.protein) &&
            Math.round(preset.carbs) === Math.round(currentGoals.carbs) &&
            Math.round(preset.fat) === Math.round(currentGoals.fat);

          return (
            <Tooltip key={preset.id}>
              <TooltipTrigger asChild>
                <Badge
                  variant={isActive ? "default" : "outline"}
                  className="cursor-default select-none"
                >
                  {preset.name}
                  {isActive && (
                    <span className="sr-only"> (currently active)</span>
                  )}
                </Badge>
              </TooltipTrigger>
              <TooltipContent side="bottom" className="max-w-[200px]">
                <div className="text-xs">
                  <p className="font-medium">{preset.name}</p>
                  <p>
                    {preset.calories} kcal &middot; P: {preset.protein}g &middot; C: {preset.carbs}g &middot; F: {preset.fat}g
                  </p>
                  <p className="mt-1 text-muted-foreground">
                    Your trainer manages your nutrition presets
                  </p>
                </div>
              </TooltipContent>
            </Tooltip>
          );
        })}
      </TooltipProvider>
    </div>
  );
}
