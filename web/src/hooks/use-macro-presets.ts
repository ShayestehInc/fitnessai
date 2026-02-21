"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { MacroPreset } from "@/types/trainer";

export function useMacroPresets(traineeId: number) {
  return useQuery<MacroPreset[]>({
    queryKey: ["macro-presets", traineeId],
    queryFn: () =>
      apiClient.get<MacroPreset[]>(
        `${API_URLS.MACRO_PRESETS}?trainee_id=${traineeId}`,
      ),
    enabled: traineeId > 0,
    staleTime: 5 * 60 * 1000,
  });
}

interface CreateMacroPresetPayload {
  trainee_id: number;
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  frequency_per_week?: number | null;
  is_default?: boolean;
}

export function useCreateMacroPreset(traineeId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateMacroPresetPayload) =>
      apiClient.post<MacroPreset>(API_URLS.MACRO_PRESETS, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["macro-presets", traineeId] });
    },
  });
}

interface UpdateMacroPresetPayload {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  frequency_per_week?: number | null;
  is_default?: boolean;
}

export function useUpdateMacroPreset(traineeId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      presetId,
      data,
    }: {
      presetId: number;
      data: UpdateMacroPresetPayload;
    }) => apiClient.put<MacroPreset>(API_URLS.macroPresetDetail(presetId), data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["macro-presets", traineeId] });
    },
  });
}

export function useDeleteMacroPreset(traineeId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (presetId: number) =>
      apiClient.delete(API_URLS.macroPresetDetail(presetId)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["macro-presets", traineeId] });
    },
  });
}

interface CopyMacroPresetPayload {
  presetId: number;
  targetTraineeId: number;
}

export function useCopyMacroPreset(sourceTraineeId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ presetId, targetTraineeId }: CopyMacroPresetPayload) =>
      apiClient.post<MacroPreset>(API_URLS.macroPresetCopyTo(presetId), {
        trainee_id: targetTraineeId,
      }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["macro-presets", sourceTraineeId],
      });
      queryClient.invalidateQueries({
        queryKey: ["macro-presets", variables.targetTraineeId],
      });
    },
  });
}
