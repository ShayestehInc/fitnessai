"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type { TraineeListItem, TraineeDetail } from "@/types/trainer";
import type { ActivitySummary } from "@/types/activity";

export function useTrainees(page: number, search: string) {
  const params = new URLSearchParams();
  params.set("page", String(page));
  if (search) params.set("search", search);

  return useQuery<PaginatedResponse<TraineeListItem>>({
    queryKey: ["trainees", page, search],
    queryFn: () =>
      apiClient.get<PaginatedResponse<TraineeListItem>>(
        `${API_URLS.TRAINEES}?${params.toString()}`,
      ),
  });
}

export function useTrainee(id: number) {
  return useQuery<TraineeDetail>({
    queryKey: ["trainee", id],
    queryFn: () => apiClient.get<TraineeDetail>(API_URLS.traineeDetail(id)),
    enabled: id > 0,
  });
}

export function useTraineeActivity(id: number, days: number = 7) {
  return useQuery<ActivitySummary[]>({
    queryKey: ["trainee", id, "activity", days],
    queryFn: () =>
      apiClient.get<ActivitySummary[]>(
        `${API_URLS.traineeActivity(id)}?days=${days}`,
      ),
    enabled: id > 0,
  });
}
