"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { User } from "@/types/user";
import type {
  TraineeViewProgram,
  NutritionSummary,
  TraineeWeightCheckIn,
} from "@/types/trainee-view";

const STALE_TIME = 5 * 60 * 1000; // 5 minutes

export function useTraineeProfile() {
  return useQuery<User>({
    queryKey: ["trainee-view", "profile"],
    queryFn: () => apiClient.get<User>(API_URLS.CURRENT_USER),
    staleTime: STALE_TIME,
  });
}

export function useTraineePrograms() {
  return useQuery<TraineeViewProgram[]>({
    queryKey: ["trainee-view", "programs"],
    queryFn: () =>
      apiClient.get<TraineeViewProgram[]>(API_URLS.TRAINEE_PROGRAMS),
    staleTime: STALE_TIME,
  });
}

export function useNutritionSummary(date: string) {
  return useQuery<NutritionSummary>({
    queryKey: ["trainee-view", "nutrition-summary", date],
    queryFn: () =>
      apiClient.get<NutritionSummary>(
        `${API_URLS.TRAINEE_NUTRITION_SUMMARY}?date=${date}`,
      ),
    staleTime: STALE_TIME,
  });
}

export function useWeightCheckIns() {
  return useQuery<TraineeWeightCheckIn[]>({
    queryKey: ["trainee-view", "weight-checkins"],
    queryFn: () =>
      apiClient.get<TraineeWeightCheckIn[]>(API_URLS.TRAINEE_WEIGHT_CHECKINS),
    staleTime: STALE_TIME,
  });
}
