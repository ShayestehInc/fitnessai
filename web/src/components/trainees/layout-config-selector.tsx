"use client";

import { useCallback, useEffect, useState } from "react";
import { Loader2, LayoutGrid, LayoutList, Rows3 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import { getErrorMessage } from "@/lib/error-utils";
import { Skeleton } from "@/components/ui/skeleton";

interface LayoutConfigSelectorProps {
  traineeId: number;
}

const LAYOUT_OPTIONS = [
  {
    value: "default",
    label: "Default",
    description: "Standard workout layout",
    icon: LayoutGrid,
  },
  {
    value: "compact",
    label: "Compact",
    description: "Condensed view for quick logging",
    icon: LayoutList,
  },
  {
    value: "detailed",
    label: "Detailed",
    description: "Expanded view with more info",
    icon: Rows3,
  },
] as const;

export function LayoutConfigSelector({ traineeId }: LayoutConfigSelectorProps) {
  const queryClient = useQueryClient();
  const [selected, setSelected] = useState("default");

  const { data, isLoading } = useQuery<{ layout: string }>({
    queryKey: ["trainee-layout", traineeId],
    queryFn: () =>
      apiClient.get<{ layout: string }>(API_URLS.traineeLayoutConfig(traineeId)),
    enabled: traineeId > 0,
  });

  useEffect(() => {
    if (data?.layout) {
      setSelected(data.layout);
    }
  }, [data]);

  const updateMutation = useMutation({
    mutationFn: (layout: string) =>
      apiClient.patch(API_URLS.traineeLayoutConfig(traineeId), { layout }),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["trainee-layout", traineeId],
      });
      toast.success("Layout updated");
    },
    onError: (err) => toast.error(getErrorMessage(err)),
  });

  const handleSelect = useCallback(
    (value: string) => {
      setSelected(value);
      updateMutation.mutate(value);
    },
    [updateMutation],
  );

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-32" />
          <Skeleton className="h-4 w-48" />
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-3 gap-3">
            {[1, 2, 3].map((i) => (
              <Skeleton key={i} className="h-24 w-full" />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Workout Layout</CardTitle>
        <CardDescription>
          Choose how workouts appear for this trainee
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-3 gap-3">
          {LAYOUT_OPTIONS.map((option) => {
            const Icon = option.icon;
            const isSelected = selected === option.value;
            return (
              <button
                key={option.value}
                onClick={() => handleSelect(option.value)}
                disabled={updateMutation.isPending}
                className={cn(
                  "flex flex-col items-center gap-2 rounded-lg border-2 p-4 text-center transition-colors",
                  isSelected
                    ? "border-primary bg-primary/5"
                    : "border-transparent hover:border-muted-foreground/30",
                )}
              >
                <Icon className={cn("h-6 w-6", isSelected ? "text-primary" : "text-muted-foreground")} />
                <div>
                  <p className="text-sm font-medium">{option.label}</p>
                  <p className="text-xs text-muted-foreground">
                    {option.description}
                  </p>
                </div>
              </button>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
