"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  ParseNaturalLanguageResponse,
  ConfirmAndSavePayload,
  MacroPreset,
} from "@/types/trainee-dashboard";

const STALE_TIME = 5 * 60 * 1000; // 5 minutes
const DATE_FORMAT = /^\d{4}-\d{2}-\d{2}$/;

function assertValidDate(date: string): void {
  if (!DATE_FORMAT.test(date)) {
    throw new Error(`Invalid date format: "${date}". Expected YYYY-MM-DD.`);
  }
}

/**
 * Mutation hook for AI natural language food parsing.
 * POST /api/workouts/daily-logs/parse-natural-language/
 */
export function useParseNaturalLanguage() {
  return useMutation({
    mutationFn: (payload: { user_input: string; date: string }) => {
      assertValidDate(payload.date);
      return apiClient.post<ParseNaturalLanguageResponse>(
        API_URLS.TRAINEE_PARSE_NATURAL_LANGUAGE,
        payload,
      );
    },
  });
}

/**
 * Mutation hook for confirming and saving parsed meal data.
 * POST /api/workouts/daily-logs/confirm-and-save/
 * Invalidates both nutrition-summary and today-log queries on success.
 */
export function useConfirmAndSaveMeal(date: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: ConfirmAndSavePayload) =>
      apiClient.post(API_URLS.TRAINEE_CONFIRM_AND_SAVE, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "nutrition-summary", date],
      });
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "today-log", date],
      });
    },
  });
}

/**
 * Mutation hook for deleting a meal entry from a daily log.
 * POST /api/workouts/daily-logs/<id>/delete-meal-entry/
 * Invalidates both nutrition-summary and today-log queries on success.
 */
export function useDeleteMealEntry(date: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { logId: number; entry_index: number }) =>
      apiClient.post(
        API_URLS.traineeDeleteMealEntry(payload.logId),
        { entry_index: payload.entry_index },
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "nutrition-summary", date],
      });
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "today-log", date],
      });
    },
  });
}

/**
 * Query hook for trainee's macro presets (read-only).
 * GET /api/workouts/macro-presets/
 */
export function useTraineeMacroPresets() {
  return useQuery<MacroPreset[]>({
    queryKey: ["trainee-dashboard", "macro-presets"],
    queryFn: () => apiClient.get<MacroPreset[]>(API_URLS.MACRO_PRESETS),
    staleTime: STALE_TIME,
    retry: 1,
  });
}
