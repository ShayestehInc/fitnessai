"use client";

import { useEffect } from "react";
import {
  MuscleGroup,
  MUSCLE_GROUP_LABELS,
  type CustomDayConfig,
} from "@/types/program";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

const SELECTABLE_GROUPS: MuscleGroup[] = [
  MuscleGroup.CHEST,
  MuscleGroup.BACK,
  MuscleGroup.SHOULDERS,
  MuscleGroup.ARMS,
  MuscleGroup.LEGS,
  MuscleGroup.GLUTES,
  MuscleGroup.CORE,
];

interface CustomDayConfiguratorProps {
  trainingDays: number;
  config: CustomDayConfig[];
  onChange: (configs: CustomDayConfig[]) => void;
}

export function CustomDayConfigurator({
  trainingDays,
  config,
  onChange,
}: CustomDayConfiguratorProps) {
  // Keep config in sync with trainingDays count
  useEffect(() => {
    if (config.length !== trainingDays) {
      const updated: CustomDayConfig[] = [];
      for (let i = 0; i < trainingDays; i++) {
        updated.push(
          config[i] ?? {
            day_name: `Day ${i + 1}`,
            label: `Day ${i + 1}`,
            muscle_groups: [],
          },
        );
      }
      onChange(updated);
    }
  }, [trainingDays]); // eslint-disable-line react-hooks/exhaustive-deps

  const toggleMuscleGroup = (dayIndex: number, mg: MuscleGroup) => {
    const updated = [...config];
    const day = { ...updated[dayIndex] };
    const groups = [...day.muscle_groups];
    const idx = groups.indexOf(mg);
    if (idx >= 0) {
      groups.splice(idx, 1);
    } else {
      groups.push(mg);
    }
    day.muscle_groups = groups;
    updated[dayIndex] = day;
    onChange(updated);
  };

  const updateLabel = (dayIndex: number, label: string) => {
    const updated = [...config];
    updated[dayIndex] = { ...updated[dayIndex], label, day_name: label };
    onChange(updated);
  };

  return (
    <div className="space-y-4">
      <Label>Configure each training day</Label>
      {config.map((day, i) => (
        <div key={i} className="rounded-lg border p-4 space-y-3">
          <Input
            value={day.label}
            onChange={(e) => updateLabel(i, e.target.value)}
            placeholder={`Day ${i + 1} name`}
            maxLength={50}
            aria-label={`Day ${i + 1} name`}
          />
          <div className="flex flex-wrap gap-1.5">
            {SELECTABLE_GROUPS.map((mg) => {
              const selected = day.muscle_groups.includes(mg);
              return (
                <Badge
                  key={mg}
                  variant={selected ? "default" : "outline"}
                  className={cn(
                    "cursor-pointer text-xs",
                    selected && "ring-1 ring-primary/20",
                  )}
                  onClick={() => toggleMuscleGroup(i, mg)}
                >
                  {MUSCLE_GROUP_LABELS[mg]}
                </Badge>
              );
            })}
          </div>
          {day.muscle_groups.length === 0 && (
            <p className="text-xs text-destructive">
              Select at least one muscle group
            </p>
          )}
        </div>
      ))}
    </div>
  );
}
