"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  WeeklyProgress,
  LatestWeightCheckIn,
  CreateWeightCheckInPayload,
  WorkoutHistoryResponse,
  WorkoutDetailData,
  SaveWorkoutPayload,
} from "@/types/trainee-dashboard";
import type { NutritionSummary, TraineeViewProgram } from "@/types/trainee-view";

const STALE_TIME = 5 * 60 * 1000; // 5 minutes

function isApiErrorWithStatus(error: unknown, status: number): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "status" in error &&
    (error as { status: number }).status === status
  );
}

export function useTraineeDashboardPrograms() {
  return useQuery<TraineeViewProgram[]>({
    queryKey: ["trainee-dashboard", "programs"],
    queryFn: () =>
      apiClient.get<TraineeViewProgram[]>(API_URLS.TRAINEE_PROGRAMS),
    staleTime: STALE_TIME,
  });
}

export function useTraineeDashboardNutrition(date: string) {
  return useQuery<NutritionSummary>({
    queryKey: ["trainee-dashboard", "nutrition-summary", date],
    queryFn: () =>
      apiClient.get<NutritionSummary>(
        `${API_URLS.TRAINEE_NUTRITION_SUMMARY}?date=${date}`,
      ),
    staleTime: STALE_TIME,
  });
}

export function useTraineeWeeklyProgress() {
  return useQuery<WeeklyProgress>({
    queryKey: ["trainee-dashboard", "weekly-progress"],
    queryFn: () =>
      apiClient.get<WeeklyProgress>(API_URLS.TRAINEE_WEEKLY_PROGRESS),
    staleTime: STALE_TIME,
  });
}

export function useTraineeLatestWeight() {
  return useQuery<LatestWeightCheckIn>({
    queryKey: ["trainee-dashboard", "latest-weight"],
    queryFn: () =>
      apiClient.get<LatestWeightCheckIn>(API_URLS.TRAINEE_WEIGHT_CHECKINS_LATEST),
    staleTime: STALE_TIME,
    retry: (failureCount, error) => {
      // Don't retry 404 (no check-ins exist)
      if (isApiErrorWithStatus(error, 404)) {
        return false;
      }
      return failureCount < 3;
    },
  });
}

export function useTraineeWeightHistory() {
  return useQuery({
    queryKey: ["trainee-dashboard", "weight-checkins"],
    queryFn: () =>
      apiClient.get<LatestWeightCheckIn[]>(API_URLS.TRAINEE_WEIGHT_CHECKINS),
    staleTime: STALE_TIME,
  });
}

export function useCreateWeightCheckIn() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateWeightCheckInPayload) =>
      apiClient.post<LatestWeightCheckIn>(
        API_URLS.TRAINEE_WEIGHT_CHECKINS,
        payload,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "weight-checkins"],
      });
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "latest-weight"],
      });
    },
  });
}

export function useTraineeWorkoutHistory(page: number = 1) {
  return useQuery<WorkoutHistoryResponse>({
    queryKey: ["trainee-dashboard", "workout-history", page],
    queryFn: () =>
      apiClient.get<WorkoutHistoryResponse>(
        `${API_URLS.TRAINEE_WORKOUT_HISTORY}?page=${page}&page_size=20`,
      ),
    staleTime: STALE_TIME,
  });
}

export function useTraineeWorkoutDetail(id: number) {
  return useQuery<WorkoutDetailData>({
    queryKey: ["trainee-dashboard", "workout-detail", id],
    queryFn: () =>
      apiClient.get<WorkoutDetailData>(API_URLS.traineeWorkoutDetail(id)),
    staleTime: STALE_TIME,
    enabled: id > 0,
  });
}

export function useSaveWorkout() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: SaveWorkoutPayload) =>
      apiClient.post(API_URLS.TRAINEE_DAILY_LOGS, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "weekly-progress"],
      });
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "workout-history"],
      });
    },
  });
}
