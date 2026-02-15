"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { TraineeProgress } from "@/types/progress";

export function useTraineeProgress(id: number) {
  return useQuery<TraineeProgress>({
    queryKey: ["trainee", id, "progress"],
    queryFn: () =>
      apiClient.get<TraineeProgress>(API_URLS.traineeProgress(id)),
    enabled: id > 0,
    staleTime: 5 * 60 * 1000,
  });
}
