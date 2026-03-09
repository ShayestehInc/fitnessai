"use client";

import { useCallback, useEffect, useState } from "react";
import { Loader2, LayoutGrid, LayoutList, Rows3, MonitorPlay } from "lucide-react";
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
import { useLocale } from "@/providers/locale-provider";

interface LayoutConfigSelectorProps {
  traineeId: number;
}

const LAYOUT_OPTIONS = [
  {
    value: "classic",
    label: "Classic",
    description: "Standard table layout",
    icon: LayoutGrid,
  },
  {
    value: "card",
    label: "Card",
    description: "Swipeable card view",
    icon: LayoutList,
  },
  {
    value: "minimal",
    label: "Minimal",
    description: "Condensed list view",
    icon: Rows3,
  },
  {
    value: "video",
    label: "Video",
    description: "Full-screen exercise demo videos",
    icon: MonitorPlay,
  },
] as const;

export function LayoutConfigSelector({ traineeId }: LayoutConfigSelectorProps) {
  const { t } = useLocale();
  const queryClient = useQueryClient();
  const [selected, setSelected] = useState("classic");

  const { data, isLoading } = useQuery<{ layout_type: string }>({
    queryKey: ["trainee-layout", traineeId],
    queryFn: () =>
      apiClient.get<{ layout_type: string }>(API_URLS.traineeLayoutConfig(traineeId)),
    enabled: traineeId > 0,
  });

  useEffect(() => {
    if (data?.layout_type) {
      setSelected(data.layout_type);
    }
  }, [data]);

  const updateMutation = useMutation({
    mutationFn: (layout_type: string) =>
      apiClient.patch(API_URLS.traineeLayoutConfig(traineeId), { layout_type }),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["trainee-layout", traineeId],
      });
      toast.success(t("trainees.layoutUpdated"));
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
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[1, 2, 3, 4].map((i) => (
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
        <CardTitle>{t("trainees.workoutLayout")}</CardTitle>
        <CardDescription>
          {t("trainees.layoutDescription")}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
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
